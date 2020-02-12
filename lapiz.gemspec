# -*- encoding: utf-8 -*-
# stub: lapiz 1.1.4 ruby lib

Gem::Specification.new do |s|
  s.name = "lapiz".freeze
  s.version = "1.1.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ajith Hussain".freeze]
  s.bindir = "exe".freeze
  s.date = "2020-02-09"
  s.description = "Lapiz is an API testing DSL for RSpec which also generates APIBlueprint files that are compatible with apiary.io".freeze
  s.email = ["csy0013@googlemail.com".freeze]
  s.files = [".gitignore".freeze, "Gemfile".freeze, "LICENSE.txt".freeze, "README.md".freeze, "Rakefile".freeze, "bin/console".freeze, "bin/setup".freeze, "lapiz.gemspec".freeze, "lib/lapiz.rb".freeze, "lib/lapiz/version.rb".freeze]
  s.homepage = "https://github.com/sparkymat/lapiz".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "2.6.12".freeze
  s.summary = "API testing DSL for RSpec".freeze

  s.installed_by_version = "2.6.12" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>.freeze, ["~> 1.10"])
      s.add_development_dependency(%q<rake>.freeze, ["~> 10.0"])
      s.add_runtime_dependency(%q<rspec>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<rails>.freeze, [">= 0"])
    else
      s.add_dependency(%q<bundler>.freeze, ["~> 1.10"])
      s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
      s.add_dependency(%q<rspec>.freeze, [">= 0"])
      s.add_dependency(%q<rails>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<bundler>.freeze, ["~> 1.10"])
    s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
    s.add_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_dependency(%q<rails>.freeze, [">= 0"])
  end
end
