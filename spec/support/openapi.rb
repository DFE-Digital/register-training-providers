generate_openapi = ENV.fetch("OPENAPI", nil) == "1"

if generate_openapi
  seed = ENV.fetch("OPENAPI_SEED", 0xFFFF)
  srand(seed)
  Faker::Config.random = Random.new(seed) if defined? Faker
end

RSpec.configure do |config|
  config.order = :defined

  RSpec::OpenAPI.path = ->(example) do
    matched = example.file_path.match(%r{spec/requests/api/v(\d+)/})
    version = matched ? matched[1] : "0"
    "public/openapi/v#{version}.yaml"
  end

  RSpec::OpenAPI.summary_builder = ->(example) do
    example.metadata.dig(:openapi, :summary) || example.description
  end

  RSpec::OpenAPI.tags_builder = ->(example) do
    example.metadata.dig(:openapi, :tags)
  end

  RSpec::OpenAPI.title = "Register of training providers API"

  # Application version
  config.before(:suite) do
    example_file = Dir["spec/requests/api/v*/**/*.rb"].first
    RSpec::OpenAPI.application_version = if example_file && (m = example_file.match(%r{api/v(\d+)/}))
                                           "v#{m[1]}"
                                         else
                                           "v0"
                                         end
  end

  config.after(:suite) do
    puts "\nGenerated API docs:"
    Dir["public/openapi/*.yaml"].each { |file| puts " - #{file}" }
  end

  config.around do |example|
    if example.metadata[:time_sensitive]
      example.run
    else
      fixed_time = Time.zone.local(current_academic_year, 9, 15, 12, 34, 56)
      Timecop.freeze(fixed_time) { example.run }
    end
  end
end
