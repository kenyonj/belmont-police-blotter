class FileParser
  DIRECTORY_DATE_FORMAT = "%Y/%m/%d"

  attr_reader :file_listing, :incidents, :coordinate_finder

  def initialize(file_listing, coordinate_finder:)
    @file_listing = file_listing
    @coordinate_finder = coordinate_finder
  end

  def parse
    puts "--- STARTING PARSING: #{file_listing.time_range} ---"

    if file_listing.fetched? && !file_listing.previously_parsed?
      File.open(file_listing.file_name, "wb") { |f| f.write(file_listing.pdf) }
      reader = PDF::Reader.new(file_listing.file_name)

      incidents = reader.pages.flat_map do |page|
        raw_incidents = page.text.gsub("\n", ";;;").gsub(/=+/m, ",").split(",").reject(&:empty?)
        raw_incidents.map { |ri| Incident.new(ri, coordinate_finder: coordinate_finder) }
      end

      incidents.each do |incident|
        conditionally_create_directory(incident)

        File.open(full_file_name_path_for(incident), "wb") do |file|
          file.puts(incident.to_markdown_with_front_matter)
        end
      end
    else
      puts "--- SKIPPING, TIME RANGE ALREADY PARSED: #{file_listing.time_range} ---"
    end

    puts "--- DONE PARSING: #{file_listing.time_range} ---"
  end

  private

  def full_file_name_path_for(incident)
    "incidents/#{incident.date_time.strftime(DIRECTORY_DATE_FORMAT)}/#{incident.number}.md"
  end

  def conditionally_create_directory(incident)
    dirname = File.dirname(full_file_name_path_for(incident))

    unless File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end
  end
end
