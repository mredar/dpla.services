require 'json'
require 'open-uri'
require 'service_log'
require 'cgi'
require 'uri'

module JsonEt
  module Extract
    # Fetch DC OAI Records
    # Return a extraction resultss along with the params used to fetch them, and
    # the http status code (e.g 302 tells us to not hit this enpoint for a while)
    class OaiDc
      include ServiceLog

      def fetch(params)
        url = build_url(params)
        service_log.info("Fetching fresh extraction from #{url}")
        get_remote_data(url, params)
      end

      def build_url(params)

        query_params = CGI::unescape(params[:query_params])
        parsed_query = CGI.parse(query_params)

        params[:batch_param] ||= nil

        if (params[:batch_param] && params[:batch_param] != '')
          query_params = URI.encode_www_form(parsed_query.except('metadataPrefix'))
          batch_param = "&#{CGI::unescape(params[:batch_param])}"
        else
          batch_param = nil
        end

        "#{params['endpoint']}?#{query_params}#{batch_param}"
      end

      def get_remote_data(url, params)
        open(url, :read_timeout => 600 ) {|e|
          raw_response = e.read
          results = Hash.from_xml(raw_response)
          code = e.status[0]
          next_batch_params = nil

          # Pull out the resumption token so that the pipeline does not need to do so
          if defined?(results["OAI_PMH"]["ListRecords"]["resumptionToken"])
            if (results["OAI_PMH"]["ListRecords"]["resumptionToken"])
              next_batch_params = CGI::escape("resumptionToken=#{results["OAI_PMH"]["ListRecords"]["resumptionToken"]}")
            end
          end

          # Extractor should always return an array of items
          if results["OAI_PMH"]["ListRecords"]
            service_log.info("Processing a Record Set")
            results = results["OAI_PMH"]["ListRecords"]['record']
          elsif results["OAI_PMH"]["ListSets"]
            service_log.info("Processing an Extraction Set")
            results = results["OAI_PMH"]["ListSets"]['set']
          end

          service_log.info("Next Batch: '#{next_batch_params}'")
          errors = (defined?(results['OAI_PMH']['error'])) ? results['OAI_PMH']['error'] : nil

          response = {
            'next_batch_params' => [next_batch_params],
            'original_params' => params,
            'records' => results,
            'http_status_code' => code,
            'errors' => errors
            }
          return response
        }
      end
    end
  end
end