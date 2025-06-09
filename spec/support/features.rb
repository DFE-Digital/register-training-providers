RSpec.configure do |config|
  config.before(:each, type: :feature) do
    config.include NavigationHelper
    config.include DfESignInUserHelper
    config.include AuthenticationHelper
  end
end
