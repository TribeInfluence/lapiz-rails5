require "lapiz/version"
require "fileutils"

class String
  def underscore
    self.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase
  end
end

module Lapiz
  def group(name, &block)
    describe(name) do
      config = YAML.load(IO.read("config.yml"))
      metadata[:base_uri] = config["server"]["base_uri"]
      metadata[:group_name] = name

      FileUtils.mkdir_p("api_docs")
      File.open("api_docs/#{name.gsub(/[^a-zA-Z_]+/,'_').underscore}.md", "w+") do |fp|
        fp.puts "# Group #{name}"
      end

      instance_eval &block
    end
  end

  def get(path, params = {}, &block)
    http_call(:get, path, params, &block)
  end

  def post(path, params, &block)
    http_call(:post, path, params, &block)
  end

  def http_call(method, path, params, &block)
    it "tests action '#{path}'", self  do |group|
      expect {
        @response = HTTParty.send(method, group.metadata[:base_uri] + path, params)
      }.to_not raise_error
      instance_eval "def response;@response;end"
      instance_eval &block

      group_name = group.metadata[:group_name]
      File.open("api_docs/#{group_name.gsub(/[^a-zA-Z_]+/,'_').underscore}.md", "a+") do |fp|
        fp.puts "# #{method.to_s.upcase} #{path}"
      end
    end
  end
end

RSpec.configure do |config|
  config.after(:suite) do
  end

  config.after(:example) do |example|
  end
end

include Lapiz
