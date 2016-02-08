module Houston
  module Roadmaps
    class ProjectGoalsController < ApplicationController
      layout "houston/roadmaps/application"
      before_filter :find_project


      def index
        authorize! :read, Milestone.new(project_id: @project.id)

        @title = "Goals for #{@project.name}"
        @milestones = @project.milestones
      end


    private

      def find_project
        @project = Project.find_by_slug! params[:project_slug]
      end

    end
  end
end
