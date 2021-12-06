require "rspec"
require "date"
require "geocoder"

Dir["lib/**/*.rb"].each { |file| require_relative "../#{file}" }
