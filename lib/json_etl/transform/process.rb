require 'json'
require 'open-uri'

module JsonEtl
  module Transform
    class Process
      include JsonEtl::Transform::Utilities

      attr_reader :output

      def output_json
        @output.to_json
      end

      def run(profile, records, enrichments)
        profile, records, enrichments = [profile, records, enrichments].map! { |data| JSON.parse(data) }
        records_profile = profile['extractor']['records']
        enrichments = process_enrichments(enrichments)
        @output = {}
        @output['next_batch_params'] = (defined?(records['next_batch_params'])) ? records['next_batch_params'] : nill
        @output['records'] = transform_records(records.fetch_slice(profile['extractor']['records']["path"]), enrichments, profile['transformer'])      
      end

      # Loop over and transform records according to the provided profile
      def transform_records(records, enrichments, profile)
        output = []
        records = record_slice(records, profile);
        records.each do |record|
          record = enrich_record(record, enrichments)
          output << process_fields(record, profile)
        end
        output
      end

      # for the sake of testing, allow users to select a subset of records
      # to transform
      def record_slice(records, profile)
        (profile.has_key?('slice')) ? records.slice(profile['slice']['start'], profile['slice']['length']) : records
      end

      # Merge additional metadata into each records
      # at a join point specified by field names and paths
      def enrich_record(record, enrichments)
          enrichments.each do |e|
            opts = e["options"];
            slice = record.fetch_slice(opts['record_path'])
            if (slice[opts["record_field_name"]])
              enrichment = {}
              enrichment[opts["record_field_name"]] = e['enrichment'][opts["origin_field_name"]  ]
              record = record.merge(enrichment)              
            end
          end
          record
      end

      # Get the portion of the enrichment that we want, index it with a 
      # provided key
      def process_enrichments(enrichments)
        output = []
        if (!enrichments.empty?)
          enrichments.each do |enrich|
            enrichment = (enrich['transform']['origin_path']) ? enrich['enrichment'].fetch_slice(enrich['transform']['origin_path']) : enrich['enrichment']
            enrichment = enrichment.to_keyed_hash(enrich['transform']['origin_field_name'])
            output << { "options" => enrich['transform'], "enrichment" => enrichment }
          end
        end
        output
      end

      # Process each field
      def process_fields(record, profile)
        dest_record = {}

        profile["fields"].each do | field_path, attributes |

          # Add the specified context to each record
          # Context is added first so that ie appears first in the hash
          dest_record['@context'] = profile['@context']
         
          # Get the field value(s) from a given field path
          vals = field_val_set(field_path, attributes, record)

          if (vals)
            # We get a single originating field path but pass the whole record
            # To allow processors to gather data from additional fields
            field_values = (attributes["processors"]) ? process_field(attributes["processors"], vals, record) : vals

            # Take the field values for a given field, map them to a dest field and merge these
            # destination fields back into the record
            dest_record = process_desitnations(field_values, attributes["field_dests"], dest_record)
          end

        end
        dest_record
      end

      def process_desitnations(values, destinations, record)
          # Loop over each destination path, grab and insert the data specified
          # by the provided regex
          destinations.each do |dest|
            field_values = fetch_values(values, dest["pattern"])
            field_values = (field_values.is_a?(Array)) ? field_values.deep_clean : field_values      
            field_values = (dest["label"]) ? apply_labels(field_values, dest["label"]) : field_values
            field = (defined?(dest)) ? field_hash_from_path(dest["path"], dest["name"], field_values) : {dest["name"] => field_values}
            record.deep_merge!(field)
          end
          record
      end

      def field_val_set(field_path, attributes, record)
        if field_path == '--LITERAL--'
          vals = attributes['value']
        else
          vals = record.fetch_slice(field_path)
        end
      end

      # Run a set of predefined processors on a field value
      # in the order that they are given (processors may build)
      # upon each other
      def process_field(processors, value, record)
        processors.each do |p|
          value = self.method(p["process"]).call(value, record, *p["args"])
        end
        value
      end

      # Allow clients to pass a url rather than the data itself
      # to save on client-side traffic
      # TODO: How do we want to test remote data?
      def fetch_remote_data(url)
        open(url) { |e| 
          if (e.status[0] != '200') 
            @output = {'errors' => "Failed request with status #{e.status[0]} for request #{e.base_uri.to_str}" }
          end
          return e.read
        }
      end       

      ################
      ## Processors ##
      ################

      def geonames_postal(data, record, username)
        output = []
        params = (data.is_a?(Array)) ? data.join(" ") : data
        placename = URI::encode(params)
        url = "http://api.geonames.org/searchJSON?q=#{placename}&maxRows=1&username=#{username}&lang=en&style=full"
        result = JSON.parse(fetch_remote_data(url))
        data = (result.has_key?('geonames')) ? result['geonames'].shift : result
        if (result.has_key?("status"))
          # TODO: allow the profile to set a unique identifier so that we can add this
          # to logs and later use for preventing duplicate db entries?
          @output = {'errors' => "Error for item #{data}: Error code #{result['status']['value']} #{result['status']['message']}" }
          []
          return 
        else
          [{"country" => data['countryName'], "state" => data['adminName1'], "county" => data['adminName2'], "name" => params, 'coordinates' => [data['lat'], data['lng']]}]
        end
      end

      # Recursively strip all elements in an array or a single string
      def rstrip(data, record)
        if (data.is_a?(Array))
          data.map! { |item| (item.is_a?(Array)) ? self.strip(item, record) : item.strip }
        else
          data.strip
        end
      end

      # whitelisted Ruby split function
      def rsplit(data, record, split_by)    
        if (data.is_a?(Array))
          data.map! { |item| (item.is_a?(Array)) ? self.split(item, record, split_by) : item.split(split_by) }
        else
          data.split(split_by)
        end
      end

      # whitelisted Ruby flatten function
      def flatten(data, record, level = nil)
        if data.kind_of?(Array)
          data.flatten(level)
        end
      end

      # whitelisted Ruby gsub
      def gsub(item, record, args)
        item.gsub(/#{args['pattern']}/, args['replacement'])
      end   

      # Return a single element of an array
      def slice(item, record, slice)
        item[slice]
      end 

      # Return a subset of an array
      def slices(item, record, args)
        slices = []
        args.each do |slice|
          slices << item[slice]
        end
        slices
      end

    end
  end
end