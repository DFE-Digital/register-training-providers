RSpec.shared_examples "a secured register API endpoint" do |url|
  it_behaves_like "a register API endpoint", url
  it_behaves_like "Rack::Attack IP throttle", url
  it_behaves_like "Rack::Attack Bearer token throttle", url
end
