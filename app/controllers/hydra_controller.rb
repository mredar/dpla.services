class HydraController < ApplicationController
  def home
    render template: 'hydra/home.json.erb'
  end

  def entrypoint
    render template: 'hydra/entry_point.json.erb'
  end
end