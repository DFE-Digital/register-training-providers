RSpec.configure do |config|
  config.around(:each, rack_attack: true) do |example|
    Rack::Attack.enabled = true
    Rack::Attack.reset!

    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

    example.run
  ensure
    Rack::Attack.cache.store.clear
    Rack::Attack.reset!
  end
end
