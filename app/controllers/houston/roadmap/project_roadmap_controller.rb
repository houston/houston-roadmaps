module Houston
  module Roadmap
    class ProjectRoadmapController < ApplicationController
      layout "houston/roadmap/application"
      
      
      def show
        @project = Project.find_by_slug!(params[:slug])
        @title = "#{@project.name} Roadmap"
        @milestones = @project.milestones
      end
      
      
      def update_order
        @project = Project.find_by_slug!(params[:slug])
        ids = Array.wrap(params[:order]).map(&:to_i).reject(&:zero?)
        
        ids.each_with_index do |id, i|
          Milestone.unscoped.where(id: id).update_all(position: i + 1)
        end
        
        head :ok
      end
      
      
    end
  end
end
