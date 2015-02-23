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
        today = Date.today
        @range = 3.weeks.before(today)..6.weeks.after(today)
        @milestones = Milestone.during(@range)
        @title = "Current Goals"
        respond_to do |format|
          format.html { render layout: "houston/roadmap/dashboard" }
          format.json { render json: {
            range: {start: @range.begin, end: @range.end},
            milestones: Houston::Roadmap::MilestonePresenter.new(@milestones) } }
        end
      end
      
      
      def show
        @project = Project.find_by_slug!(params[:slug])
        @title = "Roadmap • #{@project.name}"
        
        authorize! :read, @project.milestones.build
        
        @milestones = @project.milestones.all
        
        if request.format.json?
          render json: Houston::Roadmap::MilestonePresenter.new(@milestones)
        end
      end
      
      def update
        @project = Project.find_by_slug!(params[:slug])
        authorize! :update, @project.milestones.build
        
        RoadmapCommit.create!(
          user: current_user,
          project: @project,
          message: params[:message],
          milestone_changes: params.fetch(:roadmap, {}).values)
        
        head :ok
      end
      
      
    end
  end
end
