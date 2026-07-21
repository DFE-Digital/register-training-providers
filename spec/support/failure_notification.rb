require "rspec/core/notifications"

module FailureNotification
  def fully_formatted(failure_number, colorizer = ::RSpec::Core::Formatters::ConsoleCodes)
    result = super

    result += format_timing(example, colorizer)
    result += format_db_dump(example, colorizer)
    result += format_screenshots(example, colorizer)

    result
  end

private

  def base_dir
    @base_dir ||= "#{Dir.pwd}/"
  end

  def format_timing(example, colorizer)
    started_at = example.metadata[:test_started_at]
    finished_at = example.metadata[:test_finished_at]

    return "" unless started_at && finished_at

    duration = (finished_at - started_at).round(3)
    start_str = started_at.strftime("%H:%M:%S.%L")
    end_str = finished_at.strftime("%H:%M:%S.%L")

    colorizer.wrap("     Timing:\n", :red) +
      colorizer.wrap("     # Started: #{start_str} | Finished: #{end_str} | Duration: #{duration}s\n", :yellow)
  end

  def format_db_dump(example, colorizer)
    db_path = example.metadata[:db_dump_path]
    return "" unless db_path

    relative_path = db_path.to_s.sub(base_dir, "")

    colorizer.wrap("     DB Dump:\n", :red) +
      colorizer.wrap("     # ./#{relative_path}\n", :yellow)
  end

  def format_screenshots(example, colorizer)
    screenshot = example.metadata[:screenshot]
    return "" unless screenshot.is_a?(Hash)

    output = ""

    if (html_path = screenshot[:html])
      relative_path = html_path.to_s.sub(base_dir, "")
      output += colorizer.wrap("     HTML Screenshot:\n", :red)
      output += colorizer.wrap("     # ./#{relative_path}\n", :yellow)
    end

    if (image_path = screenshot[:image])
      relative_path = image_path.to_s.sub(base_dir, "")
      output += colorizer.wrap("     Image Screenshot:\n", :red)
      output += colorizer.wrap("     # ./#{relative_path}\n", :yellow)
    end

    output
  end
end

RSpec::Core::Notifications::FailedExampleNotification.prepend(FailureNotification)
