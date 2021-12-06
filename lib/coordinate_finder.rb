class CoordinateFinder
  BELMONT = "Belmont"
  BELMONT_STATE = "MA"
  BELMONT_ZIP = "02478"

  def initialize
    @city = BELMONT
    @state = BELMONT_STATE
    @zip = BELMONT_ZIP
  end

  def from_address(street)
    @_from_address ||= {}
    @_from_address[street] ||= begin
      location = Geocoder.search(combined_location(street))
      @_from_address[street] = location.first&.coordinates
    end
  end

  private

  attr_reader :city, :state, :zip

  def combined_location(street)
    "#{street}, #{city}, #{state} #{zip}"
  end
end
