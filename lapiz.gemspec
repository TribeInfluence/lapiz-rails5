# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'lapiz/version'

Gem::Specification.new do |spec|
  spec.name          = "lapiz"
  spec.version       = Lapiz::VERSION
  spec.authors       = ["Ajith Hussain"]
  spec.email         = ["csy0013@googlemail.com"]

  spec.summary       = %q{API testing DSL for RSpec}
  spec.description   = %q{Lapiz is an API testing DSL for RSpec which also generates APIBlueprint files that are compatible with apiary.io}
  spec.homepage      = "https://github.com/sparkymat/lapiz"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_dependency 'rspec'
end
