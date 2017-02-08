module Houston
  module Roadmaps
    class RoadmapsController < ApplicationController
      layout "houston/roadmaps/application"
      before_filter :find_roadmap, only: [:show, :history, :play, :edit, :update, :duplicate, :destroy]


      def index
        authorize! :read, Roadmap
        @title = "Roadmaps"
        @roadmaps = current_user.teams.roadmaps.preload(:projects, :milestones => {:milestone => :project}).order(:name)
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


      def play
        authorize! :read, @roadmap
        @title = "#{@roadmap.name} History"
        @start = Date.parse params[:start]
        @end = Date.parse params[:end]
        except = params.key?(:except) ? params[:except].split(",") : []

        @commits = @roadmap.commits.order(created_at: :desc).preload(:milestone_versions, :user)

        @milestones = @roadmap.milestones.including_destroyed.preload(milestone: :project).where.not(milestone_id: except)
        @markers = Houston::Roadmaps.config.markers
      end


      def edit
        authorize! :update, @roadmap
        @teams = current_user.teams.select { |team| can?(:update, Roadmap.new(team_ids: [team.id])) }
      end


      def update
        authorize! :update, @roadmap
        if @roadmap.update_attributes params[:roadmap]
          redirect_to roadmap_url(@roadmap), notice: "Roadmap updated"
        else
          render action: :edit
        end
      end


      def duplicate
        authorize! :create, @roadmap
        @roadmap = @roadmap.duplicate!(as: current_user)
        redirect_to roadmap_url(@roadmap)
      end


      def destroy
        authorize! :destroy, @roadmap
        @roadmap.destroy
        redirect_to roadmaps_path
      end


      def new
        @teams = current_user.teams.select { |team| can?(:create, Roadmap.new(team_ids: [team.id])) }
        authorize! :create, Roadmap
        @roadmap = Roadmap.new
      end


      def create
        @roadmap = Roadmap.new params[:roadmap]
        authorize! :create, @roadmap

        if @roadmap.save
          redirect_to roadmap_url(@roadmap)
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
