module Houston
  module Roadmap
    class ProjectRoadmapController < ApplicationController
      layout "houston/roadmap/application"
      
      
      def index
        authorize! :read, Milestone
        
        @projects = Project.all
        @title = "Roadmap"
      end
      
      def dashboard
        @projects = Project.includes(:uncompleted_milestones).map { |project| {
          id: project.id,
          color: project.color,
          milestones: Houston::Roadmap::MilestonePresenter.new(project.uncompleted_milestones)
        } }
        @title = "Roadmap"
        
        respond_to do |format|
          format.html { render layout: "houston/roadmap/dashboard" }
          format.json { render json: @projects }
        end
      end
      
      
      def show
        @project = Project.find_by_slug!(params[:slug])
        @title = "#{@project.name} Roadmap"
        
        authorize! :read, @project.milestones.build
        
        @milestones = @project.milestones.uncompleted
      end
      
      
      def update_order
        @project = Project.find_by_slug!(params[:slug])
        authorize! :update, @project.milestones.build
        
        ids = Array.wrap(params[:order]).map(&:to_i).reject(&:zero?)
        
        ids.each_with_index do |id, i|
          Milestone.unscoped.where(id: id).update_all(position: i + 1)
        end
        
        head :ok
      end
      
      
    end
  end
end
