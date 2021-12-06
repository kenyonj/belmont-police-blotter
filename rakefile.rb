require "faraday"
require "capybara"
require "json"
require "pdf-reader"
require "geocoder"
require "fileutils"

require_relative "lib/web_scraper"
require_relative "lib/file_parser"
require_relative "lib/file_listing"
require_relative "lib/incident"
require_relative "lib/coordinate_finder"

Geocoder.configure(lookup: :esri)

task :fetch_and_parse_all_pdfs do
  puts "--- SCRAPING ---"
  WebScraper.process(CoordinateFinder.new)
end
