require "test_helper"
require 'json'
require 'open-uri'
require 'rest_client'

describe "Transformers Controller" do 
  it 'ensures mdl transforms correctly' do
    mock_profile = JSON.parse(load_fixture('mdl_profile'))    
    mock_extraction = load_fixture('mdl_extraction')   
    transform = mock_profile['extractor']['record_enrichments'].pop
    enrichments = []
    enrichments << { 'transform' => transform['transform'], 'enrichment' => JSON.parse(load_fixture('mdl_enrichment')) } 
    
    resource = RestClient::Resource.new(mock_profile['transformer']['base_url'],        
      :timeout => 60,
      :open_timeout => 60,        
      :content_type => :json, 
      :accept => :json
    )
    records = resource.post(      
        { 
          :profile => mock_profile.to_json, 
          :records => mock_extraction, 
          :enrichments => enrichments.to_json, 
          :access_token => mock_profile['transformer']['access_token'] 
        }
      )

    filepath = File.join(Rails.root, "tmp", "tests", "records.json")
    File.open(filepath, "w") do |f|
      f.puts records.to_s.force_encoding("utf-8")
    end

    records = JSON.parse(records)

    mock_records = JSON.parse(load_fixture('mdl_transformed'))
    records.must_equal mock_records
  end
end

def load_fixture(name)
  e = File.open(File.join(File.dirname(__FILE__), "fixtures", "#{name}.json"), 'r')
  extraction = e.read
  e.close
  return extraction
end