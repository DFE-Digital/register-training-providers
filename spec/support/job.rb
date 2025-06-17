RSpec.configure do |config|
  config.before(:each, type: :job) do
    ActiveJob::Base.queue_adapter = :test
  end
end
