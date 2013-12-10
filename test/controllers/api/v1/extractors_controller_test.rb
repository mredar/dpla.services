require "minitest_helper"
require 'json'
require 'open-uri'

describe "Extractors Controler" do 
  url = 'http://localhost:8083/api/v1/extract?endpoint=http://reflections.mndigital.org/oai/oai2.php&endpoint_type=oai_dc&query_params=%26verb%3DListRecords&access_token=fefa907fca5c9e5fb2c7e01d437138b0&cache_response=true'
  it 'loads a basic extraction' do
    open(url) do |e|
      raw_response = e.read
      e.status[0].must_equal "200"
    end
  end   
end