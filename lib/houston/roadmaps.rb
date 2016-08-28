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



  add_navigation_renderer :roadmaps do
    name "Roadmaps"
    path { Houston::Roadmaps::Engine.routes.url_helpers.roadmaps_path }
    ability { |ability| ability.can?(:read, Roadmap) }
  end

  add_project_feature :goals do
    name "Goals"
    path { |project| Houston::Roadmaps::Engine.routes.url_helpers.project_goals_path(project) }
    ability { |ability, project| ability.can?(:read, project.milestones.build) }
  end

end
