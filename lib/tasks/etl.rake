require 'rake'
require 'json'
require 'open-uri'


#require '/home/fenne035/dev/dpla/dpla.etl/lib/json_etl/transform/utilities.rb'
#require '/home/fenne035/dev/dpla/dpla.etl/lib/json_etl/transform/process.rb'


desc "Run the ETL system for a given endpoint"
task :transform do


  profile = {
    :records => [],
    :slice => {'start' => 1, 'length' => 2 },
    :records_url => 'http://localhost:3000/api/v1/extract?endpoint=http://reflections.mndigital.org/oai/oai2.php&endpoint_type=oai_dc&query_limiters=%26verb%3DListRecords&access_token=388c4fb86849a3f8fe0008fa635c512d',
    :records_path => "result/OAI_PMH/ListRecords/record",
    '@context' => {
      "edm"=> "http://www.europeana.eu/schemas/edm/",
      "isShownAt"=> "edm:isShownAt",
      "dpla"=> "http://dp.la/terms/",
      "dataProvider"=> "edm:dataProvider",
      "aggregatedDigitalResource"=> "dpla:aggregatedDigitalResource",
      "state"=> "dpla:state",
      "hasView"=> "edm:hasView",
      "provider"=> "edm:provider",
      "collection"=> "dpla:aggregation",
      "object"=> "edm:object",
      "stateLocatedIn"=> "dpla:stateLocatedIn",
      "begin"=> {
          "@type"=> "xsd:date",
          "@id"=> "dpla:dateRangeStart"
      },
      "@vocab"=> "http://purl.org/dc/terms/",
      "LCSH"=> "http://id.loc.gov/authorities/subjects",
      "sourceResource"=> "edm:sourceResource",
      "name"=> "xsd:string",
      "coordinates"=> "dpla:coordinates",
      "end"=> {
          "@type"=> "xsd:date",
          "@id"=> "dpla:dateRangeEnd"
      },
      "originalRecord"=> "dpla:originalRecord"
    },
    :record_enrichments => [
      {
        "origin_field_name" => "setSpec",
        "record_field_name" => "setSpec",
        "origin_path" => "result/OAI_PMH/ListSets/set",
        "record_path" => "header/",
        "url" => "http://localhost:3000/api/v1/extract?endpoint=http://reflections.mndigital.org/oai/oai2.php&endpoint_type=oai_dc&query_limiters=%26verb%3DListSets&access_token=388c4fb86849a3f8fe0008fa635c512d"}
    ],
    :fields => {
      "metadata/dc/title" => {
          "field_dests" => [
            {
              "pattern" => ".*", 
              "path" => "/", 
              "name" => "title"
            },
            {
              "pattern" => ".*", 
              "path" => "sourceResource", 
              "name" => "title"
            }              
          ],
          "processors" => [
            {"process" => "rstrip"}
           ]
        },
      "metadata/dc/coverage" => {
          "field_dests" => [
              {
                "pattern" => ".*", 
                "path" => "sourceResource", 
                "name" => "spatial"
              }              
            ],
          "processors" => [
            {"process" => "geonames_postal", "args" => ["libsys"]}
           ]
        },
      "metadata/dc/description" => {
        "field_dests" => 
          [
            {
              "pattern" => ".*", 
              "path" => "sourceResource", 
              "name" => "description"
            }
          ]
        }, 
      "metadata/dc/contributor" => {
        "field_dests" => 
          [
            {
              "pattern" => ".*", 
              "path" => "sourceResource", 
              "name" => "contributor"
            }
          ]
        },                        
      "metadata/dc/subject" => {
        "field_dests" => 
          [
            {
              "pattern" => ".*", 
              "path" => "sourceResource", 
              "name" => "subject",
              "label" => "name"
            }
          ],            
        "processors" => [
          {"process" => "rsplit", "args" => [";\s"]},
          {"process" => "flatten"},
          {"process" => "rstrip"}
         ]
        },
      "metadata/dc/rights" => {
        "field_dests" => 
          [
            {
              "pattern" => ".*", 
              "path" => "sourceResource", 
              "name" => "rights"
            }
          ]
          }, 
      "metadata/dc/relation" => {
        "field_dests" => [
            {
              "pattern" => ".*", 
              "path" => "sourceResource", 
              "name" => "relation",
            }              
          ],
        "processors" => [
          {"process" => "rsplit", "args" => [";"]},
          {"process" => "rstrip"}
         ]
        },                          
      "metadata/dc/format" => {
        "field_dests" => [
            {
              "pattern" => ".*", 
              "path" => "sourceResource", 
              "name" => "format"
            }              
          ],
        "processors" => [
          {"process" => "rstrip"}
         ]
        },      
      "setSpec/setDescription/oclcdc/title" => {
        "field_dests" => [
            {
              "pattern" => ".*", 
              "path" => "sourceResource/collection", 
              "name" => "title"
            }
          ]
        },          
      "setSpec/setDescription/oclcdc/description" => {
        "field_dests" => [
            {
              "pattern" => ".*", 
              "path" => "sourceResource/collection", 
              "name" => "description"
            }
          ]
        },    
        "metadata/dc/type" => {
          "field_dests" => 
            [
              {
                "pattern" => ".*", 
                "path" => "sourceResource", 
                "name" => "type"
              }
            ]
          },
        "metadata/dc/creator" => {
          "field_dests" => 
            [
              {
                "pattern" => ".*", 
                "path" => "sourceResource", 
                "name" => "creator"
              }
            ]
          },
        "header/identifier" => {
          "field_dests" => 
            [
              {
                "pattern" => ".*", 
                "path" => "/", 
                "name" => "object"
              }
            ],
          "processors" => [
              {"process" => "gsub", "args" => [{'pattern' => '\/', 'replacement' => '&CISOPTR='}]},
              {"process" => "gsub", "args" => [{'pattern' => '.*\:', 'replacement' => 'http://reflections.mndigital.org/cgi-bin/thumbnail.exe?CISOROOT=/'}]}
            ]              
          },
        "metadata/dc/identifier[2]" => {
          "field_dests" => 
            [
              {
                "pattern" => ".*",
                "path" => "/",
                "name" => "isShownAt"
              }
            ]
          },
        "metadata/dc/publisher" => {
          "field_dests" => 
            [
              {
                "pattern" => ".*",
                "path" => "/",
                "name" => "dataProvider"
              }
            ]
          },
      "--LITERAL--" => {
          "value" => {
            '@id' => 'http://dp.la/api/contributor/mdl',
            "name" => "Minnesota Digital Library"
          },
          "field_dests" => 
            [
              {
                "pattern" => ".*",
                "path" => "/",
                "name" => "provider"
              }
            ]
          }

      },         
    }

   puts profile.to_json  
   
   transformer = JsonEtl::Transform::Process.new
   transformer.run(profile.to_json)
   # puts transformer.output_records.to_json
   # pp(transformer.output_records)
   # pp(transformer.inspect_errors)  
   # puts transformer.output['resumption_token']
end


