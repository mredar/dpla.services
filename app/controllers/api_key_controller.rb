class ApiKeyController < ApplicationController
  # curl -d "api_key[email]=example@example.com" localhost:3000/api_key
  def create
    @api_key = ApiKey.new(api_params)
    @api_key.save 
    render template: 'api_key/show.json.rabl'
  end

private
  def api_params
    params.require(:api_key).permit(:email)
  end
end