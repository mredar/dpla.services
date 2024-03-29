source 'http://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.0.2'

# Use sqlite3 as the database for Active Record
gem 'pg'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 4.0.0'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.0.0'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# CentOS (and RHEL?) don't come with a JS runtime
gem 'therubyracer'

# Use jquery as the JavaScript library
gem 'jquery-rails'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 1.2'

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end

# Use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# Use unicorn as the app server
gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano', group: :development

# Use debugger
# gem 'debugger', group: [:development, :test]

gem 'rdoc'
gem 'sdoc'
gem 'iconv'
gem 'bootstrap-sass', '~> 2.3.2.1'
gem 'actionpack-action_caching'
gem 'rabl'
gem 'dotenv-rails', :groups => [:development, :test]
gem "brakeman", :require => false
gem "rails_best_practices"
gem 'deep_merge'
gem 'attempt'
gem 'rest-client'

# JSON stuff, but faster
# Works as a drop-in replacement for many JSON functions
gem 'yajl-ruby'

# For caching extractions etc
gem 'redis-rails'

group :development do
  # Debug doesn't currently work so well with ruby 2.x
  gem 'byebug'
  gem 'binding_of_caller'
  gem 'meta_request'
  gem 'coderay', '~> 1.0.5'
  gem 'guard-minitest'
  gem 'better_errors'
end

group :test do
  gem "minitest"
  gem "sqlite3"
  gem 'turn'
end