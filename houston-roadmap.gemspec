$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "houston/roadmap/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "houston-roadmap"
  s.version     = Houston::Roadmap::VERSION
  s.authors     = ["Bob Lail"]
  s.email       = ["bob.lailfamily@gmail.com"]
  s.homepage    = "https://github.com/houstonmc/houston-roadmap"
  s.summary     = "A module for Houston to facilitate managing milestones"
  s.description = "A module for Houston to facilitate managing milestones"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails"

  s.add_development_dependency "sqlite3"
end
