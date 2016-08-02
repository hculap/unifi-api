# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'unifi/api/version'

Gem::Specification.new do |spec|
  spec.name          = "unifi-api"
  spec.version       = Unifi::Api::VERSION
  spec.authors       = ["hculap"]
  spec.email         = ["hculap@gmail.com"]

  spec.summary       = %q{A rewrite of https://github.com/calmh/unifi-api in Ruby.}
  spec.description   = %q{Ruby Api for UniFi Controller - Ubiquiti Networks Access Points}
  spec.homepage      = "https://github.com/hculap/unifi-api"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_dependency "httparty"
end
