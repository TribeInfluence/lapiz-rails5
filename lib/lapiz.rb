require "lapiz/version"

module Lapiz
  def group(name, &block)
    describe(name) do
      config = YAML.load(IO.read("config.yml"))
      metadata[:lapiz] = {name: name}
      metadata[:base_uri] = config["server"]["base_uri"]
      instance_eval &block
    end
  end

  def get(path, &block)
    it "tests action '#{path}'" do
      @response = HTTParty.get(path)
      block.call
    end
  end

  def response
    @response
  end
end

RSpec.configure do |config|
  config.before(:suite) do
    # Create or clear api-docs folder
  end

  config.after(:example) do |example|
  end
end

include Lapiz
