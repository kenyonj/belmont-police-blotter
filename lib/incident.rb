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

  def to_h
    {
      number: number,
      date_time: date_time,
      street_name: street_name&.gsub(WHITESPACE_ONLY, " "),
      latitude: latitude,
      longitude: longitude,
      type: type&.gsub(WHITESPACE_ONLY, " "),
    }
  end

  private

  attr_reader :raw_incident, :coordinate_finder

  def number
    @_number ||= raw_incident.
      split("Date:").first.
      split("#:").last[/\d+/]
  end

  def date_time
    @_date_time ||= begin
      raw_date_time = raw_incident.split("Date:").last.split("Type:").first
      raw_date = raw_date_time[RAW_DATE_FORMAT]&.gsub(/\D/, "-")
      raw_time = raw_date_time[RAW_TIME_FORMAT]

      return unless raw_date && raw_time

      DateTime.parse("#{raw_date} #{raw_time} #{TZ}")
    end
  end

  def street_name
    @_street_name ||= raw_incident.
      split("Location:").last.
      split(";;;").first&.
      [](RAW_STREET_FORMAT)&.
      gsub(/\s/, " ")
  end

  def latitude
    coordinate_finder.from_address(street_name)&.first
  end

  def longitude
    coordinate_finder.from_address(street_name)&.last
  end

  def type
    @_type ||= raw_incident.
      split("Type:").last.
      split(";;;").first&.
      [](RAW_TYPE_FORMAT)&.
      gsub(/\s/, " ")
  end
end
