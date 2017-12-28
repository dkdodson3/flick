# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'flick/version'

Gem::Specification.new do |spec|
  spec.name          = "flick"
  spec.version       = Flick::VERSION
  spec.authors       = ["Justin"]
  spec.email         = ["justin.ison@gmail.com"]

  spec.summary       = %q{A CLI to capture screenshots, video, logs, and device information for Android (Devices & Emulators) and iOS (Devices).}
  spec.description   = %q{A CLI with helpful QA tools for iOS and Android from the command line}
  spec.homepage      = "https://github.com/isonic1/flick"
  spec.license       = "MIT"

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = ["flick"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", '~> 3.4', '>= 3.4.0'
  spec.add_dependency "parallel", '~> 1.6', '>= 1.6.2'
  spec.add_dependency "colorize", "~> 0.8.1"
  spec.add_dependency "commander", '~> 4.4', '>= 4.4.0'
  spec.add_dependency "json"
  spec.add_dependency "wannabe_bool", "~> 0.5.0"
  spec.add_dependency "awesome_print", '~> 1.6', '>= 1.6.1'
  spec.add_dependency "os", "~> 0.9.6"
  spec.add_dependency "sys-proctable", '~> 1.1', '>= 1.1.1'
  spec.add_dependency "apktools", '~> 0.7.1', '>= 0.7.1'
  spec.add_dependency "ffi"
  spec.add_dependency "eyes_images"
  spec.add_dependency "pry"
end