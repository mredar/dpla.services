require 'yajl/json_gem'
require 'open-uri'

module JsonEt
  module Transform
    class Process
      include ServiceLog
      include JsonEt::Transform::Utilities

      attr_reader :output

      def initialize
        @output = {}
        @output['errors'] = []
      end

      def output_json
        @output.to_json
      end

      def run(profile, records, enrichments)
        profile, records, enrichments = [profile, records, enrichments].map! { |data| JSON.parse(data) }
        # Todo: allow users to passed in pre-processed enrichments (keyed)
        enrichments = process_enrichments(enrichments)
        records = records.fetch_slice(profile['extractor']['records']["origin_path"])
        @output['records'] = transform_records(records, enrichments, profile['transformer'])
      end

      # Loop over and transform records according to the provided profile
      def transform_records(records, enrichments, profile)
        output = []
        records = record_slice(records, profile);
        records.each_with_index do |record, index|
          service_log.info("Transforming record # #{index}")
          record = enrich_record(record, enrichments)
          output << process_fields(record, profile)
        end
        output
      end

      # for the sake of testing, allow users to select a subset of records
      # to transform
      def record_slice(records, profile)
        if profile.has_key?('slice')
          service_log.info("Slicing Extraction at # #{profile['slice']['start']} ending at #{profile['slice']['length']}")
          records = records.slice(profile['slice']['start'], profile['slice']['length'])
        end
        records
      end

      # Merge additional metadata into each records
      # at a join point specified by field names and paths
      def enrich_record(record, enrichments)
          enrichments.each do |e|
            config = e["config"];

            record_key = record.fetch_slice(config['dest_path'])[config["dest_key_field_name"]]
            if (record_key)
              # If we have a value in the records has that matches a key in the enrichment,
              # we then merge it into the record, "enriching" it
              if e['enrichment'][record_key]
                enrichment = {}
                enrichment[config["dest_key_field_name"]] = e['enrichment'][record_key]
                record = record.merge(enrichment)
              end
            end
          end
          record
      end

      # Get the portion of the enrichment that we want, index it with a
      # provided key
      def process_enrichments(enrichments)
        output = []
        if (enrichments)
          enrichments.each do |enrich|
            enrichment = (enrich['transform']['origin_path']) ? enrich['enrichment'].fetch_slice(enrich['transform']['origin_path']) : enrich['enrichment']
            enrichment = (enrichment.respond_to?('to_keyed_hash')) ? enrichment.to_keyed_hash(enrich['transform']['origin_key_field_name']) : enrichment
            output << { "config" => enrich['transform'], "enrichment" => enrichment }
          end
        end
        output
      end

      # Process each field
      def process_fields(record, profile)
        dest_record = {}

        profile["fields"].each do |dest_path, config|

          # Add the specified context to each record
          # Context is added first so that it appears first in the hash
          dest_record['@context'] = profile['@context']

          # Get the field value(s) from a given field path
          field_vals = get_field_values(config, record)
          if (field_vals)
            # We get a single originating field path but pass the whole record
            # To allow processors to gather data from other fields
            field_values = (config["processors"]) ? process_field(config["processors"], field_vals, record) : field_vals

            # Take the field values for a given field, map them to a dest field and merge these
            # destination fields back into the record
            dest_record = dest_merge(field_values, dest_path, config['label'], dest_record)
          end
        end
        dest_record['originalRecord'] = record
        dest_record
      end

      # Run a set of predefined processors on a field value
      # in the order that they are given (processors may build)
      # upon each other
      def process_field(processors, value, record)

        processors.each do |p|
          begin
            if defined? p["process"]
              if (p["args"].is_a?(Hash))
                value = self.method(p["process"]).call(value, record, p["args"])
              else
                value = self.method(p["process"]).call(value, record, *p["args"])
              end
            end
          rescue Exception => e
            msg = "Processor Error for #{p} on for value `#{value}` on record `#{record}. Error Message: #{e.message}"
            service_log.error("Processor Error for #{p} on for value `#{value}` on record `#{record}. Error Message: #{e.message}")
            @output['errors'] << msg
            raise e
          end
        end
        value
      end

      def dest_merge(field_values, dest_path, label, record)
        field_values = (field_values.is_a?(Array)) ? field_values.deep_clean : field_values
        field_values = (label) ? apply_labels(field_values, label) : field_values
        field = field_hash_from_path(dest_path, field_values)
        record.deep_merge!(field)
      end

      # Allow clients to pass a url rather than the data itself
      # to save on client-side traffic
      # TODO: How do we want to test remote data?
      def fetch_remote_data(url)
        open(url) { |e|
          if (e.status[0] != '200')
            @output['errors'] << "Failed request with status #{e.status[0]} for request #{e.base_uri.to_str}"
          end
          return e.read
        }
      end

      ################
      ## Processors ##
      ################

      # Adds prefixes and/or suffixes to a field value
      def affix(value, record, args)
        "#{args['prefix']}#{value}#{args['suffix']}"
      end

      # TODO: refactor this fugly mess
      def geonames_match(data, args)
        data = geonames_normalze_match(data)
        if (args['match_sets'])
          args['match_sets'].each do |match_set|
            match_set['matches'].each do |match|
              match = geonames_normalze_match(match)
              if match == data
                return match_set['returns']
              end
            end
          end
        end
        nil
      end

      def geonames_normalze_match(match)
        (match.is_a?(Array)) ? match.sort.join("").downcase : match.downcase
      end

      def geonames_postal(data, record, args)
        if (default = geonames_match(data, args))
          return default
        else
          output = []
          # Allow a local config option for the purpose of integration testing
          username = APP_CONFIG['geonames']['username'] ? APP_CONFIG['geonames']['username'] : args['username']
          params = (data.is_a?(Array)) ? data.join(" ") : data
          placename = URI::encode(params)
          url = "http://ws.geonames.net//searchJSON?q=#{placename}&maxRows=1&username=#{username}&lang=en&style=full"
          result = JSON.parse(fetch_remote_data(url))
          count = result['totalResultsCount']
          data = (result.has_key?('geonames')) ? result['geonames'].shift : result
          if result.has_key?("status")
            # TODO: allow the profile to set a unique identifier so that we can add this
            # to logs and later use for preventing duplicate db entries?
            @output['errors'] << "Error for item #{data}: Error code #{result['status']['value']} #{result['status']['message']}"
            return []
          elsif count > 0
            [{"county" => data['adminName2'], "name" => params, "state" => data['adminName1'], 'coordinates' => "#{data['lat']}, #{data['lng']}", "country" => data['countryName']}]
          else
            msg = "geonames_postal: Couldn't find squat for #{params}"
            service_log.warn(msg)
            @output['errors'] << msg
            output
          end
        end
      end

      # Recursively strip all elements in an array or a single string
      def rstrip(data, record)
        if !data.nil?
          if (data.is_a?(Array))
            # rip out any nils in the array itself
            data.reject! { |c| c.nil? }
            if !data.compact.empty?
              data.map! { |item| (item.is_a?(Array)) ? self.rstrip(item, record) : item.strip }
            end
          else
            data.strip
          end
        end
      end

      # whitelisted Ruby split function
      def rsplit(data, record, split_by)
        if (data.is_a?(Array))
          data.map! { |item| (item.is_a?(Array)) ? self.rsplit(item, record, split_by) : item.split(split_by) }
        else
          data = data.split(split_by)
        end
      end

      # whitelisted Ruby flatten function
      def flatten(data, record, level = nil)
        if data.kind_of?(Array)
          data.flatten(level)
        end
      end

      # whitelisted Ruby flatten function
      def unique(data, record)
        if data.kind_of?(Array)
          data.uniq
        end
      end

      # whitelisted Ruby gsub
      def gsub(data, record, args = {})
        if (data.is_a?(Array))
          data.map! { |item| (item.is_a?(Array)) ? self.gsub(item, record, args) : item.gsub(/#{args['pattern']}/, args['replacement']) }
        else
          if data
            data.gsub(/#{args['pattern']}/, args['replacement'])
          end
        end
      end

      # Return a single element of an array
      def slice(item, record, slice)
        if item.is_a?(Array)
          if !item[slice.to_i].nil?
            return item[slice.to_i]
          else
            return item
          end
        end
      end

      # Wrapper for Ruby join method, return the object if it is not an array
      def join(item, record, join_by)
        if item.is_a?(Array)
          return item.join(join_by)
        else
          return item
        end
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