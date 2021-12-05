require "faraday"
require "capybara"
require "json"
require "pdf-reader"

require_relative "lib/web_scraper"
require_relative "lib/file_parser"
require_relative "lib/file_listing"

task :fetch_and_parse_all_pdfs do
  puts "--- SCRAPING ---"
  WebScraper.process
end
