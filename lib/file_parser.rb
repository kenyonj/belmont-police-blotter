class FileParser
  JSON_DB_FILE = "db/json/data.json"
  NEW_INCIDENT_SEPARATOR =
    "==========================================================================="

  attr_reader :file_listing, :incidents

  def initialize(file_listing)
    @file_listing = file_listing
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
        raw_incidents.map { |ri| Incident.new(ri) }
      end

      incidents.each do |incident|
        json["incidents"] << incident.to_h
      end
    else
      puts "--- SKIPPING, TIME RANGE ALREADY PARSED: #{file_listing.time_range} ---"
    end

    File.write(JSON_DB_FILE, JSON.dump(json))
  end

  class Incident
    attr_reader :incident_number

    def initialize(raw_incident)
      @incident_number = raw_incident[/\d{8}/]
      @raw_incident = raw_incident
    end

    def to_h
      {
        number: incident_number,
        date_it_happened: "today",
      }
    end
  end
end
