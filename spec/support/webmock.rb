RSpec.configure do |config|
  config.before do
    allow(Addresses::GeocodeService).to receive(:call).and_return(
      { latitude: nil, longitude: nil }
    )
  end
end
