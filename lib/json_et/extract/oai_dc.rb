require 'json'
require 'open-uri'

module JsonEt
  module Extract
    # Fetch DC OAI Records
    # Return a extraction results along with the params used to fetch them, and
    # the http status code (e.g 302 tells us to not hit this enpoint for a while)
    class OaiDc

      def self.fetch(params)
        url = self.build_url(params)
        self.get_remote_data(url, params)
      end

      def self.build_url(params)
        prefix = (defined?(params['batch_params']) && !params['batch_params'].nil?) ? "?#{params['batch_params']}" : '?metadataPrefix=oai_dc'
        query = params[:query_params] ? CGI::unescape(params[:query_params]) : nil
        "#{params['endpoint']}#{prefix}#{query}"
      end

      def self.get_remote_data(url, params)
        attempt(5, 5) {
         open(url) {|e|
            raw_response = e.read
            result = Hash.from_xml(raw_response)
            code = e.status[0]
            # Pull out the resumption token so that the pipeline does not need to do so
            next_batch_params = defined?(result["OAI_PMH"]["ListRecords"]["resumptionToken"]) ? CGI::escape("resumptionToken=#{result["OAI_PMH"]["ListRecords"]["resumptionToken"]}") : nil
            errors = (defined?(result['OAI_PMH']['error'])) ? result['OAI_PMH']['error'] : nil
            response = {
              'next_batch_params' => next_batch_params,
              'original_params' => params,
              'result' => result,
              'http_status_code' => code,
              'errors' => errors
              }
            return response
          }
        }
      end
    end
  end
end