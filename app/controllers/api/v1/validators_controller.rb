require 'yajl/json_gem'
require 'digest/sha1'

module Api
 module V1
    class ValidatorsController < ApplicationController
      include ServiceLog
      before_filter :restrict_access

      def diff
        valid = Validator.new
        @response = valid.diff(params)
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