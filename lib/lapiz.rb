require "lapiz/version"
require "fileutils"
require "cgi"

class String
  def underscore
    self.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase
  end
end

class Hash
  def flatten
    new_hash = self.dup

    while new_hash.values.map(&:class).include?(Hash)
      updated_hash = {}
      new_hash.each_pair do |k,v| 
        if v.is_a?(Hash)
          v.each_pair do |ik, iv| 
            updated_hash["#{k},#{ik}"] = iv
          end
        else
          updated_hash[k.to_s] = v
        end
      end
      new_hash = updated_hash
    end

    new_hash = new_hash.to_a.map{ |e|
      if e[0].include?(",")
        main = e[0].split(",").first
        rest = e[0].split(",")[1..-1]
        rest_string = rest.map{ |r| "[#{r}]" }.join("")
        ["#{main}#{rest_string}", e[1]]
      else
        e
      end
    }.to_h

    new_hash
  end
end

module Lapiz
  def group(name, &block)
    describe(name) do
      config = YAML.load(IO.read("config.yml"))
      metadata[:base_uri] = config["server"]["base_uri"]
      metadata[:group_name] = name

      FileUtils.mkdir_p("api_docs")
      File.open("api_docs/#{name.gsub(/[^a-zA-Z_]+/,'_').underscore}.txt", "w+") do |fp|
        fp.puts "# Group #{name}"
        fp.puts
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

      request_type = nil
      unless method == :head || method == :get
        # Attempt to find request type
        if @response.request.options[:headers]
          request_type = @response.request.options[:headers]["Content-Type"]
        end

        if  request_type.nil? # it was not set explicitly
          # if body is present, assume they meant x-www-form-urlencoded
          request_type = "x-www-form-urlencoded"
        end
      end

      group_name = group.metadata[:group_name]
      File.open("api_docs/#{group_name.gsub(/[^a-zA-Z_]+/,'_').underscore}.txt", "a+") do |fp|
        fp.puts "## #{method.to_s.upcase} #{path}"
        fp.puts

        if request_type
          if request_type == "application/json"
            fp.puts "+ Request (#{request_type})"
          elsif request_type == "x-www-form-urlencoded"
            fp.puts "+ Parameters"

            if @response.request.options[:body]
              flattened_params = @response.request.options[:body] ? @response.request.options[:body].flatten : {}
              flattened_params.each_pair do |k,v| 
                fp.puts "    + #{CGI.escape(k)}: \"#{v.to_s}\" (#{v.class.name})"
              end
            end
          end
        end

        if @response.body
          fp.puts
          fp.puts "+ Response #{@response.code} (#{@response.content_type})"
          fp.puts 

          hash = JSON.parse(@response.body)

          fp.puts JSON.pretty_generate(hash).split("\n").map{ |line| "        #{line}" }.join("\n")

          fp.puts
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.after(:suite) do
    config = YAML.load(IO.read("config.yml"))
    base_uri = config["server"]["base_uri"]

    File.open("api_docs/api.md", "w+") do |fp| 
      fp.puts "FORMAT: 1A"
      fp.puts "HOST: #{base_uri}"
      fp.puts
      fp.puts "# #{config["meta"]["title"]}"
      fp.puts
      fp.puts config["meta"]["description"]
      fp.puts
      
      Dir["api_docs/*.txt"].each do |f|
        IO.readlines(f).map(&:chomp).each do |line|
          fp.puts line
        end
      end
    end
  end

  config.after(:example) do |example|
  end
end

include Lapiz