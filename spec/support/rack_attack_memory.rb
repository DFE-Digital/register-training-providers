RSpec.configure do |config|
  config.around(:each, rack_attack: true) do |example|
    Rack::Attack.enabled = true
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

    example.run
  ensure
    Rack::Attack.cache.store.clear
  end
end
