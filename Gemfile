ruby '2.5.3'
source 'https://rubygems.org'

gem 'rails', '~> 5.0'
gem 'sidekiq', '~> 5' # Upgrade to 5 with rails. BREAKING CHANGES
gem 'doorkeeper', '~> 4'
gem "bootsnap", "~> 1.3"

# To resize active storage images:
# Revise if this is needed after Rails 6.0
gem 'image_processing'

gem 'ancestry'
gem 'api-pagination'
gem 'api_cache'
gem 'awesome_print', require: false
gem 'aws-sdk-s3'
gem 'bcrypt'#, '~> 3.1.7'
gem 'browser'#, '1.0.1'
gem 'c_geohash', require: false
gem 'countries'
gem 'dalli'
gem 'date_validator'
gem 'diffy', require: false
gem 'fast_blank'
gem 'figaro'
gem 'fog-aws'
gem 'friendly_id'#, '~> 5.1.0'
gem 'geocoder'
#gem "google-cloud-storage", "~> 1.11", require: false
gem 'jbuilder'
gem 'kaminari'
gem 'listen'#, '~> 3.0.0'
gem 'mailgun_rails'
gem 'moneta'
gem 'multi_json'
gem 'net-telnet'
gem 'oauth2', require: false
gem 'oj_mimic_json'
gem 'oj'#, '2.18.3' # 3.0.0 breaks tests:  https://github.com/ohler55/oj/blob/master/CHANGELOG.md#300---2017-04-24
gem 'parallel', require: false
gem 'pg'#, '~> 0.20' # pg 1 only works on rails 5.1.5+
gem 'pg_search'
gem 'premailer-rails'
gem 'puma'
gem 'pundit'
gem 'rack-cache'
gem 'rack-contrib'
gem 'rack-cors', require: 'rack/cors'
gem 'rack-timeout', require: "rack/timeout/base"
gem 'ransack'
gem 'redis'#, '3.0.7'
gem 'responders'
gem 'rufus-scheduler'
gem 'sentry-raven'
gem 'sinatra'#, '>= 1.3.0', require: nil
gem 'stamp'
gem 'versionist', github: 'bploetz/versionist'
gem 'workflow'
gem 'timezone', '~> 1.0'

# eventMachine MQTT handler
gem 'em-mqtt'#, '~> 0.0.4'

group :production do
  gem 'rails_12factor'
end

group :test do
  gem 'database_cleaner'
  gem 'simplecov', require: false
  gem 'zonebie'
  gem 'codeclimate-test-reporter', require: nil
  gem 'timecop'
  gem 'vcr'
  gem 'webmock'
end

group :development do
  gem 'pry-rails'
  gem 'spring-commands-rspec'
  gem 'spring'
  gem 'sshkit'#, '1.7.1'
  gem 'sshkit-sudo'
  gem 'rubocop', require: false
  gem "parallel_tests"
  gem "rails-erd"
end

group :development, :test do
  # gem 'rspec_api_blueprint', require: false
  gem 'cane'
  gem 'faker'
  gem 'brakeman', github: 'presidentbeef/brakeman', require: false
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'shoulda-matchers',
    github: 'thoughtbot/shoulda-matchers', require: false,
    ref: '8e68d99217fac5dedceeeba226ea1f2d9be01e1b'
  gem 'guard-rspec'
  gem 'railroady'
  gem 'byebug'
  # gem 'web-console', '~> 2.0'
  gem 'rdoc'
end
