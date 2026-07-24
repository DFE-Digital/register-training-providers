require "json"
require "fileutils"

module FailureArtifacts
module_function

  def capture(example)
    FileUtils.mkdir_p("tmp/db_dumps")

    timestamp = Time.zone.now.strftime("%Y-%m-%d-%H-%M-%S")

    description = example.full_description
                         .downcase
                         .gsub(/\s+/, "-")
                         .gsub(/["<>|:*?\\\/\r\n]/, "")
                         .gsub(/[^a-z0-9\-_]/, "")

    path = Rails.root.join(
      "tmp/db_dumps",
      "#{description}_#{timestamp}.json"
    )

    dump = {
      "_metadata" => {
        "example" => example.full_description,
        "location" => example.location,
        "exception" => example.exception.class.name,
        "message" => example.exception.message,
        "time" => Time.current.iso8601
      }
    }

    ApplicationRecord.descendants
                     .reject(&:abstract_class?)
                     .select(&:table_exists?)
                     .sort_by(&:name)
                     .each do |model|
      dump[model.name] = model.order(model.primary_key).map(&:attributes)
    rescue StandardError => e
      dump[model.name] = {
        error: e.class.name,
        message: e.message
      }
    end

    File.write(
      path,
      JSON.pretty_generate(dump)
    )

    path.to_s
  end
end
