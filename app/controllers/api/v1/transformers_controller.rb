module Api
 module V1
    class TransformersController < ApplicationController
      include ServiceLog
      before_filter :restrict_access

      # post /transform/api/v1
      def transform
        service_log.info("New Transformation Begun for #{@api_key.email} with profile #{params[:profile]}")
        transformer = JsonEt::Transform::Process.new
        transformer.run(params[:profile], params[:records], params[:enrichments])
        @response = transformer.output_json
        render template: 'api/v1/response.json.erb'
      end

      private
        def restrict_access
          @api_key = ApiKey.find_by_api_key(params[:api_key])
          head :unauthorized unless @api_key
        end
    end
  end
end