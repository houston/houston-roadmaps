require "houston/tickets"
require "houston/roadmaps/milestone_ext"
require "houston/roadmaps/project_ext"
require "houston/roadmaps/team_ext"

module Houston
  module Roadmaps
    class Railtie < ::Rails::Railtie

      # The block you pass to this method will run for every request in
      # development mode, but only once in production.
      config.to_prepare do
        ::Milestone.send(:include, Houston::Roadmaps::MilestoneExt)
        ::Project.send(:include, Houston::Roadmaps::ProjectExt)
        ::Team.send(:include, Houston::Roadmaps::TeamExt)
      end

    end
  end
end
