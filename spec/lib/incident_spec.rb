require_relative "../spec_helper"

describe Incident do
  context "#to_markdown_with_front_matter" do
    it "returns the proper hash from the raw incident" do
      raw_incident = "Incident #: 12345678     Date: 2021‐11‐22 02:04:46     Type: PARKING ENFORCE;;;Location: DARTMOUTH ST;;;"
      coordinate_finder = CoordinateFinder.new
      latitude, longitude = coordinate_finder.from_address("DARTMOUTH ST")
      expected_front_matter_array = [
        "---",
        "number: 12345678",
        "date_time: #{DateTime.parse("22 November 2021 2:04:46 AM Americas/New_York")}",
        "location: DARTMOUTH ST",
        "latitude: #{latitude}",
        "longitude: #{longitude}",
        "type: PARKING ENFORCE",
        "google_maps_link: https://maps.google.com/?q=#{latitude},#{longitude}",
        "---",
        "",
        raw_incident,
      ]

      incident = Incident.new(raw_incident, coordinate_finder: coordinate_finder)

      expect(incident.to_markdown_with_front_matter).to eql(expected_front_matter_array)
    end

    it "returns the proper hash from the raw incident with intersection" do
      first_raw_incident = ";;;Incident #: 21020112     Date: 2021‐12‐04 16:50:32     Type: TRAFFIC STOP;;;Location: COMMON ST & TRAPELO RD;;;;;;"
      second_raw_incident = ";;;;;;Incident #: 21014559     Date: 2021‐09‐07 17:30:34     Type: TRAFFIC STOP;;;Location: AGASSIZ ST & TRAPELO RD;;;"
      coordinate_finder = CoordinateFinder.new
      first_latitude, first_longitude = coordinate_finder.from_address("COMMON ST & TRAPELO RD")
      second_latitude, second_longitude = coordinate_finder.from_address("AGASSIZ ST & TRAPELO RD")
      first_expected_front_matter_array = [
        "---",
        "number: 21020112",
        "date_time: #{DateTime.parse("04 December 2021 16:50:32 Americas/New_York")}",
        "location: COMMON ST & TRAPELO RD",
        "latitude: #{first_latitude}",
        "longitude: #{first_longitude}",
        "type: TRAFFIC STOP",
        "google_maps_link: https://maps.google.com/?q=#{first_latitude},#{first_longitude}",
        "---",
        "",
        first_raw_incident,
      ]
      second_expected_front_matter_array = [
        "---",
        "number: 21014559",
        "date_time: #{DateTime.parse("07 September 2021 17:30:34 Americas/New_York")}",
        "location: AGASSIZ ST & TRAPELO RD",
        "latitude: #{second_latitude}",
        "longitude: #{second_longitude}",
        "type: TRAFFIC STOP",
        "google_maps_link: https://maps.google.com/?q=#{second_latitude},#{second_longitude}",
        "---",
        "",
        second_raw_incident,
      ]

      first_incident = Incident.new(first_raw_incident, coordinate_finder: coordinate_finder)
      second_incident = Incident.new(second_raw_incident, coordinate_finder: coordinate_finder)
      first_result = first_incident.to_markdown_with_front_matter
      second_result = second_incident.to_markdown_with_front_matter

      first_expected_front_matter_array.each_with_index do |expected_value, index|
        expect(expected_value).to eql(first_result[index])
      end

      second_expected_front_matter_array.each_with_index do |expected_value, index|
        expect(expected_value).to eql(second_result[index])
      end
    end

    it "returns the proper hash from the raw incident with text before address" do
      raw_incident = ";;;Incident #: 21020096     Date: 2021‐12‐04 10:26:42     Type: PARKING ENFORCE;;;;;;Location: WAVERLEY SQUARE PARKING LOT / 15 CHURCH ST;;;"
      coordinate_finder = CoordinateFinder.new
      latitude, longitude = coordinate_finder.from_address("15 CHURCH ST")
      expected_front_matter_array = [
        "---",
        "number: 21020096",
        "date_time: #{DateTime.parse("04 December 2021 10:26:42 Americas/New_York")}",
        "location: 15 CHURCH ST",
        "latitude: #{latitude}",
        "longitude: #{longitude}",
        "type: PARKING ENFORCE",
        "google_maps_link: https://maps.google.com/?q=#{latitude},#{longitude}",
        "---",
        "",
        raw_incident,
      ]

      incident = Incident.new(raw_incident, coordinate_finder: coordinate_finder)
      result = incident.to_markdown_with_front_matter

      expected_front_matter_array.each_with_index do |expected_value, index|
        expect(expected_value).to eql(result[index])
      end
    end
  end
end
