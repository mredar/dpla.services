module Api
 module V1
    class TransformersController < ApplicationController
      before_filter :restrict_access 

      # GET /transform/api/v1
      def extract
        @response = Transformer.fetch(params) 
        render template: 'api/v1/transformers/response.json.erb'             
      end

      private
        def restrict_access
          api_key = ApiKey.find_by_access_token(params[:access_token])
          head :unauthorized unless api_key
        end      
    end
  end
end