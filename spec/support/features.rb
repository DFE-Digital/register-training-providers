RSpec.configure do |config|
  config.before(:each, type: :feature) do
    config.include NavigationHelper
  end
end
