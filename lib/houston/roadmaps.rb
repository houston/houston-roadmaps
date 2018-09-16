require "houston/roadmaps/engine"
require "houston/roadmaps/configuration"

module Houston
  module Roadmaps
    extend self

    def dependencies
      [ :tickets, :todolists ]
    end

    def config(&block)
      @configuration ||= Roadmaps::Configuration.new
      @configuration.instance_eval(&block) if block_given?
      @configuration
    end

  end



  navigation
    .add_link(:roadmaps) { Houston::Roadmaps::Engine.routes.url_helpers.roadmaps_path }
    .name("Roadmaps")
    .ability { can?(:read, Roadmap) }

  project_features
    .add(:goals) { |project| Houston::Roadmaps::Engine.routes.url_helpers.project_goals_path(project) }
    .name("Goals")
    .ability { |project| can?(:read, project.milestones.build) }

end
