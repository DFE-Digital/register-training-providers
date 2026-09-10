require "fileutils"
require "json"

module LivingDocsHelpers
module_function

  def base_dir(example)
    filename = example.description.gsub(/[^0-9A-Za-z.-]/, "_")
    "tmp/living_docs/#{filename}".tap { |dir| FileUtils.mkdir_p(dir) }
  end

  def steps_dir(example)
    "#{base_dir(example)}/steps".tap { |dir| FileUtils.mkdir_p(dir) }
  end

  def take_screenshot(session, path_template, example)
    count = increment_screenshot_counter(session)
    path = "#{steps_dir(example)}/step_#{sprintf('%03d', count)}_#{path_template}.png"

    session.driver.with_playwright_page do |pw_page|
      pw_page.screenshot(path:)
    end

    puts "\n📸 Screenshot saved: #{path}"
  rescue StandardError => e
    puts "\n⚠️ Notice: Skipped screenshot step #{count || '?'} (#{e.message.split(':').first})"
  end

  def increment_screenshot_counter(session)
    count = (session.instance_variable_get(:@screenshot_counter) || 0) + 1
    session.instance_variable_set(:@screenshot_counter, count)
    count
  end

  def extract_test_code(example)
    file_path = File.expand_path(example.metadata[:file_path])
    lines = File.readlines(file_path)

    # Walk backwards to find the block start
    start_idx = example.metadata[:line_number] - 1
    while start_idx > 0 && !lines[start_idx].match?(/^\s*(scenario|it|fscenario|fit|feature|describe|context)\b/)
      start_idx -= 1
    end

    extracted_code = []
    depth = 0
    block_started = false

    lines[start_idx..].each do |line|
      extracted_code << line
      code = line.gsub(/".*?"/, '""').gsub(/'.*?'/, "''") # Strip strings
      code = code.gsub(/#\{.*?\}/, "").split("#").first.to_s # Strip interpolation/comments

      depth += code.scan(/\b(do|if|unless|case|begin|def|class|module)\b/).count
      depth -= code.scan(/\bend\b/).count
      depth += code.scan("{").count - code.scan("}").count

      block_started = true if depth > 0
      break if block_started && depth <= 0
    end

    extracted_code.join
  end

  def generate_json_data(example)
    base = base_dir(example)
    json_path = "#{base}/data.json"

    # 1. Gather screenshots
    screenshot_files = Dir.glob("#{base}/steps/*.png").sort
    screenshots_data = screenshot_files.map.with_index do |path, idx|
      basename = File.basename(path)
      step_label = if basename.include?("initial")
                     "Initial State / Page Load"
                   elsif basename.include?("final_state")
                     "Final Test State"
                   else
                     "Action Step"
                   end

      {
        step_number: idx + 1,
        label: step_label,
        file_name: basename,
        relative_path: "steps/#{basename}"
      }
    end

    # 2. Determine Video path convention
    filename = File.basename(base)
    video_relative_path = "#{filename}.webm"

    # 3. Build the comprehensive JSON structure
    output_data = {
      metadata: {
        title: example.description,
        file_path: example.metadata[:file_path],
        line_number: example.metadata[:line_number],
        timestamp: Time.now.utc.iso8601,
        # Check exception directly to guarantee accurate passed/failed status
        status: example.exception ? "failed" : "passed"
      },
      media: {
        video_file: video_relative_path,
        total_screenshots: screenshots_data.size,
        screenshots: screenshots_data
      },
      code: {
        language: "ruby",
        snippet: extract_test_code(example)
      }
    }

    # 4. Write to disk
    File.write(json_path, JSON.pretty_generate(output_data))
    puts "\n📄 Structured JSON data saved to: #{json_path}"
  end
end
