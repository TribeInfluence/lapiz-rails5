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
      if e[0].to_s.include?(",")
        main = e[0].split(",").first
        rest = e[0].split(",")[1..-1]
        rest_string = rest.map{ |r| "[#{r}]" }.join("")
        ["#{main}#{rest_string}", e[1]]
      else
        [e[0].to_s, e[1]]
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

  def patch(path, params, &block)
    http_call(:patch, path, params, &block)
  end

  def put(path, params, &block)
    http_call(:put, path, params, &block)
  end

  def delete(path, params, &block)
    http_call(:delete, path, params, &block)
  end

  def http_call(method, path_pattern, params, &block)
    path = path_pattern.gsub(/{([^{}]*)}/) { # path_pattern contains {field=default_value}. gsub it with default value 
      if $1.start_with?("?")
        "?" + $1.sub("?","").split(",").join("&")
      else
        $1.split("=").last
      end
    }
    pattern = path_pattern.gsub(/{([^{}]*)}/) {  # same as above, but gsub it with field
      if $1.start_with?("?")
        "{?" + $1.sub("?","").split(",").map{ |e| e.split("=").first }.join(",") + "}"
      else
        "{#{$1.split("=").first}}"
      end
    }

    if pattern.start_with?("?")
      path = "#{pattern}=#{path}"
    end

    if block.nil?
      config = YAML.load(IO.read("config.yml"))
      base_uri = config["server"]["base_uri"]
      return HTTParty.send(method, base_uri + path, params)
    end

    it "tests action '#{pattern}'", self  do |group|
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
        fp.puts "## #{method.to_s.upcase} #{pattern}"
        fp.puts

        if @response.request.options[:description]
          fp.puts @response.request.options[:description].lstrip
        end 

        if request_type || (path != pattern) # path != pattern when there is a url pattern # TODO: Use better checks
          if request_type == "application/json"
            fp.puts "+ Request (#{request_type})"
          elsif request_type == "x-www-form-urlencoded" || (path != pattern)
            fp.puts "+ Parameters"

            flattened_params = {}
            if @response.request.options[:body]
              flattened_params = @response.request.options[:body] ? @response.request.options[:body].flatten : {}
              flattened_params.each_pair do |k,v| 
                description = nil
                if @response.request.options[:parameter_descriptions]
                  description = @response.request.options[:parameter_descriptions][k.to_s] || @response.request.options[:parameter_descriptions][k.to_sym]
                end
                fp.puts "    + #{CGI.escape(k)}: (#{v.class.name})#{description ? " - #{description}" : ""}"
              end
            end

            # This converts param_desc hash to an array ([[k1,v1],[k2,v2]]), removes any which are already in the body (and hence documented), and then convers back to hash
            @response.request.options[:parameter_descriptions].to_a.map{|e| [e[0].to_s, e[1]]}.reject{|e| flattened_params.keys.include?(e[0])}.to_h.each_pair do |k,v|
              fp.puts "    + #{CGI.escape(k)}: (String) - #{v}"
            end
          end
        end

        if @response.request.options[:headers]
          fp.puts
          fp.puts "+ Request"
          fp.puts
          fp.puts "    + Headers"
          fp.puts
          @response.request.options[:headers].each_pair  do |k,v|
            fp.puts "            #{k}: #{v}"
          end
          fp.puts
        end

        if @response.body && (@response.code / 100 == 2)
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
