require_relative "../spec_helper"

describe Incident do
  context "#to_h" do
    it "returns the proper hash from the raw incident" do
      raw_incident = "Incident #: 12345678     Date: 2021‐11‐22 02:04:46     Type: PARKING ENFORCE;;;Location: DARTMOUTH ST;;;"
      coordinate_finder = CoordinateFinder.new
      latitude, longitude = coordinate_finder.from_address("DARTMOUTH ST")
      expected_hash = {
        number: "12345678",
        date_time: DateTime.parse("22 November 2021 2:04:46 AM Americas/New_York"),
        street_name: "DARTMOUTH ST",
        latitude: latitude,
        longitude: longitude,
        type: "PARKING ENFORCE",
      }

      incident = Incident.new(raw_incident, coordinate_finder: coordinate_finder)

      expect(incident.to_h).to eql(expected_hash)
    end
  end
end
