source 'https://rubygems.org'
ruby '2.3.0'

gem 'rails', '~> 4.2.1'

gem 'addressable', require: 'addressable/uri'
gem 'bootstrap-sass'
gem 'flag-icon-sass', :git => 'git@github.com:cfiorini/flag-icon-sass.git', :branch => 'master'
gem 'delayed_job_active_record'
gem 'dotenv'
gem 'haml-rails'
gem 'has_secure_token'
gem 'honeybadger', '~> 2.0'
gem 'jquery-rails'
gem 'newrelic_rpm'
gem 'octokit', '4.1.0', require: false
gem 'omniauth'
gem 'omniauth-auth0'
gem 'pg'
gem 'rack-timeout'
gem 'rugged', '~> 0.23.0'
gem 'sass-rails'
gem 'therubyracer'
gem 'uglifier'
gem 'unicorn'
gem 'unicorn-rails'
gem 'virtus'
gem 'whenever'

group :development do
  gem 'better_errors', require: false
  gem 'binding_of_caller', require: false
  gem 'foreman', require: false
  gem 'spring'
  gem 'spring-commands-rspec'
end

group :development, :test do
  gem 'rspec-rails'
  gem 'rubocop'
  gem 'pry', require: false
end

group :production do
  gem 'rails_12factor'
end

group :test do
  gem 'capybara'
  gem 'codeclimate-test-reporter', require: false
  gem 'cucumber-rails', require: false
  gem 'database_cleaner'
  gem 'factory_girl'
  gem 'rack-test', require: 'rack/test'
  gem 'shoulda-matchers'
  gem 'simplecov', require: false
  gem 'webmock', require: false
end
