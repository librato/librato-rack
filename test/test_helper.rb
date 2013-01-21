require 'bundler'
Bundler.setup

require 'pry'
require 'minitest/autorun'
# require 'mocha/setup'

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require 'librato/rack'

# require File.expand_path("../dummy/config/environment.rb",  __FILE__)
# require "rails/test_help"

# Configure capybara
# require 'capybara/rails'
# Capybara.default_driver = :rack_test
# Capybara.default_selector = :css

# Load support files
#Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }
