require "test_helper"
require 'json'
require 'open-uri'

describe "Extractors Controller" do 
  it 'ensures the mock OAI service is running' do
    url = 'http://localhost:8083/api/v1/extract?endpoint=http://localhost:3000/oai/show&endpoint_type=oai_dc&query_params=%26verb%3DListRecords&access_token=fefa907fca5c9e5fb2c7e01d437138b0&cache_response=true'    
    open(url) do |e|
      e.status[0].must_equal "200"
    end
  end
end