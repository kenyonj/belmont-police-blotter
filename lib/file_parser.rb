class FileParser
  JSON_DB_FILE = "db/json/data.json"
  NEW_INCIDENT_SEPARATOR =
    "==========================================================================="

  attr_reader :file_listing, :incidents, :coordinate_finder

  def initialize(file_listing, coordinate_finder:)
    @file_listing = file_listing
    @coordinate_finder = coordinate_finder
  end

  def parse
    file = File.read(JSON_DB_FILE)
    json = JSON.parse(file)

    if file_listing.fetched?
      json["time_range"] ||= []
      json["time_range"] << file_listing.time_range

      File.open(file_listing.file_name, "wb") { |f| f.write(file_listing.pdf) }
      reader = PDF::Reader.new(file_listing.file_name)

      incidents = reader.pages.flat_map do |page|
        raw_incidents = page.text.gsub("\n", ";;;").gsub(/=+/m, ",").split(",").reject(&:empty?)
        raw_incidents.map { |ri| Incident.new(ri, coordinate_finder: coordinate_finder) }
      end

      incidents.each do |incident|
        json["incidents"] ||= []
        json["incidents"] << incident.to_h
      end
    else
      puts "--- SKIPPING, TIME RANGE ALREADY PARSED: #{file_listing.time_range} ---"
    end

    puts "--- DONE PARSING: #{file_listing.time_range} ---"
    File.write(JSON_DB_FILE, JSON.dump(json))
  end
end
