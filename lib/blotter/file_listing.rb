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
    if pdf_file_exists?
      @fetched = true
      @pdf = File.read(file_name)
    else
      puts "--- FETCHING start: #{start_date} -- end: #{end_date} ---"
      if pdf_file_exists?
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

  def previously_parsed?
    return @_previously_parsed if defined?(@_previously_parsed)


    parsed_dates = (start_date..end_date).each_with_object(
      Hash.new { |outer_h, outer_k| outer_h[outer_k] = Hash.new { |h, k| h[k] = [] } },
    ) do |date, dates|
      dates[date.strftime("%Y")][date.strftime("%m")] << date.strftime("%d")
    end

    directories_exist = parsed_dates.keys.flat_map do |year|
      parsed_dates[year].keys.flat_map do |month|
        parsed_dates[year][month].flat_map do |day|
          File.directory?("_incidents/#{year}/#{month}/#{day}")
        end
      end
    end

    @_previously_parsed = directories_exist.all?
  end

  private

  def pdf_file_exists?
    File.file?(file_name)
  end
end
