require "houston/roadmap/engine"
require "houston/roadmap/configuration"

module Houston
  module Roadmap
    extend self

    def config(&block)
      @configuration ||= Roadmap::Configuration.new
      @configuration.instance_eval(&block) if block_given?
      @configuration
    end

  end
end
