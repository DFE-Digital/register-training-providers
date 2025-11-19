RSpec.configure do |config|
  config.before(:each) do |example|
    if example.metadata[:env]
      example.metadata[:env].each do |key, value|
        if value.nil?
          allow(Env).to receive(key.to_sym).and_call_original
        else
          allow(Env).to receive(key.to_sym).and_return(value)
        end
      end
    end
  end
end
