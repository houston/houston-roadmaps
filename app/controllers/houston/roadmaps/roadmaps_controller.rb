module Houston
  module Roadmaps
    class RoadmapsController < ApplicationController
      layout "houston/roadmaps/application"
      before_filter :find_roadmap, only: [:show, :history, :edit, :update, :update_milestones, :destroy]


      def index
        authorize! :read, Roadmap
        @title = "Roadmaps"
        @roadmaps = Roadmap.all.preload(:projects, :milestones => {:milestone => :project}).order(:name)
      end


      def show
        authorize! :read, @roadmap
        @title = @roadmap.name
        @goals = @roadmap.projects.goals.preload(:project)
        @milestones = @roadmap.milestones.preload(milestone: :project)

        render template: "houston/roadmaps/roadmaps/show_editable" if can?(:update, @roadmap)
      end


      def history
        authorize! :read, @roadmap
        @title = "#{@roadmap.name} History"

        @commits = @roadmap.commits.order(created_at: :desc).preload(:milestone_versions, :user)
        @commit_id = params[:commit_id].to_i

        @milestones = @roadmap.milestones.including_destroyed.preload(milestone: :project)
        @markers = Houston::Roadmaps.config.markers
      end


      def edit
        authorize! :update, @roadmap
      end


      def update
        authorize! :update, @roadmap
        if @roadmap.update_attributes params[:roadmap]
          redirect_to roadmaps_url, notice: "Roadmap created"
        else
          render action: :edit
        end
      end


      def new
        authorize! :create, Roadmap
        @roadmap = Roadmap.new
      end


      def create
        authorize! :create, Roadmap
        @roadmap = Roadmap.create params[:roadmap]
        if @roadmap.persisted?
          redirect_to roadmaps_url, notice: "Roadmap created"
        else
          render action: :new
        end
      end


    protected

      def find_roadmap
        @roadmap = Roadmap.find params[:id]
      end

    end
  end
end
