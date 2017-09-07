$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "sengiri/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "sengiri"
  s.version     = Sengiri::VERSION
  s.authors     = ["mewlist"]
  s.email       = ["mewlist@mewlist.com"]
  s.homepage    = "https://github.com/mewlist"
  s.summary     = "Database sharding for Ruby on Rails"
  s.description = "Database sharding for Ruby on Rails. Supports sharding migration, access and transaction"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.0"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec"
end
