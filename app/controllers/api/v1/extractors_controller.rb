require 'yajl/json_gem'
require 'digest/sha1'

module Api
 module V1
  	class ExtractorsController < ApplicationController
      include ServiceLog
      before_filter :restrict_access

		  # GET /extract/api/v1/
			def extract
        service_log.info("Extraction has begun for client user #{@api_key.email}")
        sha = Extractor.sha(params)
        extract =  extraction("exctract-#{sha}", params)
        @response = (params[:pretty]) ? JSON.pretty_generate(extract) : extract.to_json
        if extract['errors']
          render template: 'api/v1/extractors/response.json.erb', status: 500
        else
          render template: 'api/v1/extractors/response.json.erb'
        end

			end

      private
        def extraction(key, params)
          if params['cache_response']
            Rails.cache.fetch(key, :expires_in => 1.year) do
              Extractor.fetch(params)
            end
          else
            Extractor.fetch(params)
          end
        end

        def restrict_access
          @api_key = ApiKey.find_by_api_key(params[:api_key])
          head :unauthorized unless @api_key
        end
  	end
  end
end