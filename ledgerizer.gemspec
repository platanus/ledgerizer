$:.push File.expand_path("lib", __dir__)

# Maintain your gem"s version:
require "ledgerizer/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name          = "ledgerizer"
  s.version       = Ledgerizer::VERSION
  s.authors       = ["Platanus", "Leandro Segovia"]
  s.email         = ["rubygems@platan.us", "ldlsegovia@gmail.com"]
  s.homepage      = "https://github.com/platanus/ledgerizer"
  s.summary       = "A double-entry accounting system for Rails applications"
  s.description   = "A double-entry accounting system for Rails applications"
  s.license       = "MIT"

  s.files = `git ls-files`.split($/).reject { |fn| fn.start_with? "spec" }
  s.bindir = "exe"
  s.executables = s.files.grep(%r{^exe/}) { |f| File.basename(f) }
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", ">= 5.2.0"

  s.add_dependency "enumerize"
  s.add_dependency "money-rails"
  s.add_dependency "require_all"

  s.add_development_dependency "annotate"
  s.add_development_dependency "coveralls"
  s.add_development_dependency "factory_bot_rails"
  s.add_development_dependency "guard-rspec"
  s.add_development_dependency "pg"
  s.add_development_dependency "pry"
  s.add_development_dependency "pry-rails"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "shoulda-matchers"
end
