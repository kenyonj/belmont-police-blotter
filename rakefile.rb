require_relative "lib/blotter"

Geocoder.configure(lookup: :esri)

task :fetch_and_parse_all_pdfs do
  puts "--- SCRAPING ---"
  WebScraper.process(CoordinateFinder.new)
end
