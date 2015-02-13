# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'paysafecard/version'

Gem::Specification.new do |spec|
  spec.name          = "paysafecard"
  spec.version       = Paysafecard::VERSION
  spec.authors       = ["Phillipp Röll"]
  spec.email         = ["phillipp.roell@trafficplex.de"]
  spec.summary       = %q{Paysafecard SOAP API wrapper}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "pry"
  spec.add_dependency "savon", "~> 2.7.0"
  spec.add_dependency "rubyntlm", "~> 0.3.2"
end
