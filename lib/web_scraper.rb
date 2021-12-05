class WebScraper
  URL_FOR_POLICE_BLOTTER = "https://www.belmontpd.org/resident-resources/pages/police-blotter"

  def self.process
    new.process
  end

  def process
    response = Faraday.get(URL_FOR_POLICE_BLOTTER)

    if response.success?
      node = Capybara.string(response.body)
      nodes = node.find_css(".field-name-field-file-attachment span.file")

      file_listings = nodes.map { |node| FileListing.new(node) }
      pending_parsings = file_listings.map { |file_listing| FileParser.new(file_listing) }
      fetch(file_listings)
      parse(pending_parsings)
    else
      raise "Error fetching blotter page!"
    end
  end

  private

  def fetch(file_listings)
    file_listings.each(&:fetch)
  end

  def parse(pending_parsings)
    pending_parsings.each(&:parse)
  end
end
