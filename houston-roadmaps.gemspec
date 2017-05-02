$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "houston/roadmaps/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "houston-roadmaps"
  spec.version     = Houston::Roadmaps::VERSION
  spec.authors     = ["Bob Lail"]
  spec.email       = ["bob.lailfamily@gmail.com"]

  spec.summary     = "A module for Houston to facilitate managing milestones"
  spec.description = "A module for Houston to facilitate managing milestones"
  spec.homepage    = "https://github.com/houston/houston-roadmaps"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  spec.test_files = Dir["test/**/*"]

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]
  spec.test_files = Dir["test/**/*"]

  spec.add_dependency "neat-rails", ">= 0.2.0"
  spec.add_dependency "houston-core", ">= 0.8.0.pre"
  spec.add_dependency "houston-tickets"

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 11.2"
end
