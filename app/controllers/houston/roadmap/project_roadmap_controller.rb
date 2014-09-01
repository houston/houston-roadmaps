module Houston
  module Roadmap
    class ProjectRoadmapController < ApplicationController
      layout "houston/roadmap/application"
      
      
      def index
        authorize! :read, Milestone
        
        @milestones = Milestone.visible
        @title = "Roadmap"
      end
      
      def dashboard
        @milestones = Milestone.visible
        @title = "Roadmap"
        respond_to do |format|
          format.html { render layout: "houston/roadmap/dashboard" }
          format.json { render json: Houston::Roadmap::MilestonePresenter.new(@milestones) }
        end
      end
      
      
      def show
        @project = Project.find_by_slug!(params[:slug])
        @title = "Roadmap • #{@project.name}"
        
        authorize! :read, @project.milestones.build
        
        @milestones = @project.milestones.uncompleted
      end
      
      
    end
  end
end
