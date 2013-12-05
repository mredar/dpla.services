require 'json'
require 'open-uri'

module JsonEtl
  module Extract
    # Fetch DC OAI Records
    # Return a extraction results along with the params used to fetch them, and
    # the http status code (e.g 302 tells us to not hit this enpoint for a while)
    class OaiDc
      def self.fetch(params)
        if !params['next_batch_params']
          url = "#{params[:endpoint]}?metadataPrefix=oai_dc#{params[:query_params]}"
        else
          next_batch_params = CGI::unescape(params[:next_batch_params])
          url = "#{params[:endpoint]}?#{next_batch_params}#{params[:query_params]}"
        end 

        open(url) {|e|
          raw_response = e.read
          result = Hash.from_xml(raw_response)
          code = e.status[0]
          # Pull out the resumption token so that the pipeline does not need to do so 
          next_batch_params = defined?(result["OAI_PMH"]["ListRecords"]["resumptionToken"]) ? CGI::escape("resumptionToken=#{result["OAI_PMH"]["ListRecords"]["resumptionToken"]}") : nil

          errors = (defined?(result['result']['OAI_PMH']['error'])) ? result['result']['OAI_PMH']['error'] : nil
          response = {
            'next_batch_params' => next_batch_params, 
            'original_params' => params,
            'result' => result, 
            'http_status_code' => code,
            'errors' => errors
            }        
          return response.to_json
        }
      end
    end
  end
end