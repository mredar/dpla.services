require 'rake'
require 'json'
require 'open-uri'

require "#{Rails.root}/lib/json_etl/transform/utilities.rb"
require "#{Rails.root}/lib/json_etl/transform/process.rb"

desc "Run the ETL system for a given endpoint"
task :transform do

   profile = File.read("#{Rails.root}/test/fixtures/profile.json")
   pp(RestClient.post "http://glacial-ocean-9697.herokuapp.com/api/v1/transform", profile, :content_type => :json, :accept => :json)
   # transformer = JsonEtl::Transform::Process.new
   # transformer.run(profile)
   # puts transformer.output_records.to_json
   # pp(transformer.output_records)
   # pp(transformer.inspect_errors)  
   # puts transformer.output['resumption_token']
end


