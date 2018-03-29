# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'authograph/version'

Gem::Specification.new do |spec|
  spec.name          = "authograph"
  spec.version       = Authograph::VERSION
  spec.authors       = ["Ignacio Baixas"]
  spec.email         = ["ignacio@platan.us"]

  spec.summary       = "Flexible HTTP request HMAC signing and validation"
  spec.description   = "
HTTP request signing and validation library with support for header signing and multiple backends.
"
  spec.homepage      = "https://github.com/SurBTC/authograph"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "guard", "~> 2.14"
  spec.add_development_dependency "guard-rspec", "~> 4.7"
  spec.add_development_dependency "webmock", "~> 3.3"
  spec.add_development_dependency "faraday", "~> 0.14"
  spec.add_development_dependency "pry"
end
