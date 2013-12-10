
# See: http://stackoverflow.com/questions/4235782/rails-3-library-not-loading-until-require/6797707#6797707
Dir[Rails.root + 'lib/json_etl/extensions/*.rb'].each do |file|
  require file
end