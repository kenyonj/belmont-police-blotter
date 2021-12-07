class WebScraper
  URL_FOR_POLICE_BLOTTER = "https://www.belmontpd.org/resident-resources/pages/police-blotter"
  WAIT_TIME_BETWEEN_FILE_PARSING_IN_SECONDS = 10

  def initialize(coordinate_finder)
    @coordinate_finder = coordinate_finder
  end

  def self.process(coordinate_finder)
    new(coordinate_finder).process
  end

  def process
    response = Faraday.get(URL_FOR_POLICE_BLOTTER)

    if response.success?
      node = Capybara.string(response.body)
      nodes = node.find_css(".field-name-field-file-attachment span.file")

      file_listings = nodes.map { |node| FileListing.new(node) }

      pending_parsings = file_listings.map do |file_listing|
        FileParser.new(file_listing, coordinate_finder: coordinate_finder)
      end

      fetch(file_listings)
      parse(pending_parsings)
    else
      raise "Error fetching blotter page!"
    end
  end

  private

  attr_reader :coordinate_finder

  def fetch(file_listings)
    file_listings.each(&:fetch)
  end

  def parse(pending_parsings)
    pending_parsings.each do |pending_parsing|
      unless pending_parsing.file_listing.previously_parsed?
        WAIT_TIME_BETWEEN_FILE_PARSING_IN_SECONDS.times do |n|
          puts "Sleeping for #{n + 1}/#{WAIT_TIME_BETWEEN_FILE_PARSING_IN_SECONDS} "\
            "seconds to cool down map api usage..."
          sleep(1)
        end
      end

      pending_parsing.parse
    end
  end
end
