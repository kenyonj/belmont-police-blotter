class Incident
  TZ = "Americas/New_York"
  RAW_DATE_FORMAT = /\d{4}.\d{2}.\d{2}/
  RAW_TIME_FORMAT = /\d{2}:\d{2}:\d{2}/
  RAW_STREET_FORMAT = /[A-z]+.[A-z]+$/
  RAW_TYPE_FORMAT = /[A-z]+.[A-z]+$/
  WHITESPACE_ONLY = /[^a-zA-Z0-9]/

  def initialize(raw_incident, coordinate_finder:)
    @raw_incident = raw_incident
    @coordinate_finder = coordinate_finder
  end

  def to_markdown_with_front_matter
    [
      "---",
      "number: #{number}",
      "date_time: #{date_time}",
      "location: #{location}",
      "latitude: #{latitude}",
      "longitude: #{longitude}",
      "type: #{type.gsub(WHITESPACE_ONLY, " ")}",
      "google_maps_link: https://maps.google.com/?q=#{latitude},#{longitude}",
      "---",
      "",
      raw_incident,
    ]
  end

  def date_time
    @_date_time ||= begin
      raw_date_time = raw_incident.split("Date:").last.split("Type:").first
      raw_date = raw_date_time[RAW_DATE_FORMAT]&.gsub(/\D/, "-") || "1970-01-01"
      raw_time = raw_date_time[RAW_TIME_FORMAT] || "12:00:00"

      DateTime.parse("#{raw_date} #{raw_time} #{TZ}")
    end
  end

  def number
    @_number ||= raw_incident.
      split("Date:").first.
      split("#:").last[/\d+/]
  end

  private

  attr_reader :raw_incident, :coordinate_finder

  def location
    @_location ||= begin
      raw_location = raw_incident.
        split("Location:").last.
        split(";;;").first&.
        [](1..-1)&.
        gsub("\xC2\xA0", " ")

      if raw_location&.include?("&") || !(raw_location =~ /\d+/)
        raw_location
      else
        raw_location&.[](/\d+\s\D+\s\D+/)
      end
    end
  end

  def latitude
    coordinate_finder.from_address(location)&.first
  end

  def longitude
    coordinate_finder.from_address(location)&.last
  end

  def type
    @_type ||= raw_incident.
      split("Type:").last.
      split(";;;").first&.
      [](RAW_TYPE_FORMAT)&.
      gsub(/\s/, " ") || "UNKNOWN TYPE"
  end
end
