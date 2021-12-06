class FileListing
  EXISTING_DATE_FORMAT = "%m-%d-%y"
  NEW_DATE_FORMAT = "%Y-%m-%d"
  OUTPUT_PATH = "db/pdfs/"

  attr_reader :start_date, :end_date, :pdf_href, :pdf

  def initialize(node)
    link = node.css("a")
    start_date, end_date = link.inner_html.split(".").first.split("_to_")
    @start_date = Date.strptime(start_date, EXISTING_DATE_FORMAT)
    @end_date = Date.strptime(end_date, EXISTING_DATE_FORMAT)
    @pdf_href = link.first.attributes["href"].value
  end

  def fetch
    if file_exists?
      @fetched = true
      @pdf = File.read(file_name)
    else
      puts "--- FETCHING start: #{start_date} -- end: #{end_date} ---"
      if file_exists?
        @fetched = true
        @pdf = File.read(file_name)
      else
        response = Faraday.get(pdf_href)

        if response.success?
          @fetched = true
          @pdf = response.body
        else
          @fetched = false
          raise "Error fetching pdf!"
        end
      end
    end
  end

  def time_range
    "#{start_date.strftime(NEW_DATE_FORMAT)}--#{end_date.strftime(NEW_DATE_FORMAT)}"
  end

  def file_name
    "#{OUTPUT_PATH}#{time_range}.pdf"
  end

  def fetched?
    !!@fetched
  end

  private

  def file_exists?
    File.file?(file_name)
  end
end
