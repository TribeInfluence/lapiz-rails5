require "lapiz/version"

RSpec.configure do |config|
  configure.before(:suite) do
    # Create or clear api-docs folder
  end

  config.after(:example) do |example|
  end
end
