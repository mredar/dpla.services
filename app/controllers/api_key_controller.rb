class ApiKeyController < ApplicationController

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
