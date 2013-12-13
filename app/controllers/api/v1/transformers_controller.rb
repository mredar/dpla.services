module Api
 module V1
    class TransformersController < ApplicationController
      before_filter :restrict_access 
      skip_before_action :verify_authenticity_token

      # post /transform/api/v1
      def transform
        transformer = JsonEt::Transform::Process.new
        transformer.run(params[:profile], params[:records], params[:enrichments])
        @response = transformer.output_json
        render template: 'api/v1/transformers/response.json.erb'             
      end

      private 
        def restrict_access      
          api_key = ApiKey.find_by_api_key(params[:api_key])
          head :unauthorized unless api_key
        end      
    end
  end
end