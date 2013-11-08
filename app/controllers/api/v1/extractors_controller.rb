require 'digest/sha1'

module Api
 module V1
  	class ExtractorsController < ApplicationController
      before_filter :restrict_access 

		  # GET /extract/api/v1/ 
			def extract   
        sha = Extractor.sha(params)
        @response = extraction("exctract-#{sha}", params)
        render template: 'api/v1/extractors/response.json.erb'             
			end

      private
        def extraction(key, params)
          Rails.cache.fetch(key, :expires_in => 24.hours) do
           Extractor.fetch(params) 
          end
        end

        def restrict_access
          api_key = ApiKey.find_by_access_token(params[:access_token])        
          head :unauthorized unless api_key
        end
  	end
  end
end

# %26from%3D2013-10-01
