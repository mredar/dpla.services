class HydraController < ApplicationController
  def home
    render template: 'hydra/home.json.erb', content_type: "application/json"
  end

  def entrypoint
    render template: 'hydra/entry_point.json.erb', content_type: "application/json"
  end  
end