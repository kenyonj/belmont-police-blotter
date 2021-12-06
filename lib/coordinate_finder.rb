class CoordinateFinder
  BELMONT = "Belmont"
  BELMONT_STATE = "MA"
  BELMONT_ZIP = "02478"

  def initialize
    @from_addresses = {}
  end

  def from_address(street)
    from_addresses[street] ||= begin
      location = Geocoder.search(combined_location(street))
      from_addresses[street] = location.first&.coordinates
    end
  end

  private

  attr_reader :from_addresses

  def combined_location(street)
    "#{street}, #{BELMONT}, #{BELMONT_STATE} #{BELMONT_ZIP}"
  end
end
