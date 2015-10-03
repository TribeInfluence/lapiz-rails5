require "lapiz/version"

module Lapiz
  def group(name, &block)
    describe(name) do
      config = YAML.load(IO.read("config.yml"))
      metadata[:base_uri] = config["server"]["base_uri"]
      instance_eval &block
    end
  end

  def get(path, &block)
    it "tests action '#{path}'", self  do |group|
      expect {
        @response = HTTParty.get(group.metadata[:base_uri] + path)
      }.to_not raise_error
      block.call
    end
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
