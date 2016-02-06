require "houston/roadmaps/engine"
require "houston/roadmaps/configuration"

module Houston
  module Roadmaps
    extend self

    def config(&block)
      @configuration ||= Roadmaps::Configuration.new
      @configuration.instance_eval(&block) if block_given?
      @configuration
    end

  end
end
