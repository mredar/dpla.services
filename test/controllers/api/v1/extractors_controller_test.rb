require "test_helper"
require 'json'
require 'open-uri'

describe "Extractors Controller" do
  it 'ensures the mock OAI service is running' do
    url = 'http://localhost:8083/api/v1/extract?endpoint=http://localhost:3002/oai/show&endpoint_type=oai_dc&query_params=%26verb%3DListRecords&api_key=aff3aeac5688976f3762622920de4d80&cache_response=true&pretty=true'
    open(url) do |e|
      e.status[0].must_equal "200"
    end
  end
end