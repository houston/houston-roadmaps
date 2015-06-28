require "houston/roadmap/engine"
require "houston/roadmap/configuration"

module Houston
  module Roadmap
    extend self
    
    attr_reader :config
    
  end
  
  Roadmap.instance_variable_set :@config, Roadmap::Configuration.new
end
