module Houston
  module Roadmaps
    class RoadmapsController < ApplicationController
      layout "houston/roadmaps/application"
      before_action :find_roadmap, only: [:show, :history, :play, :edit, :update, :duplicate, :destroy]


      def index
        authorize! :read, Roadmap
        @title = "Roadmaps"
        @roadmaps = Roadmap.preload(:commits).order(:name).find_all { |roadmap| can? :read, roadmap }
      end


      def show
        authorize! :read, @roadmap
        @title = @roadmap.name
        @goals = @roadmap.projects.goals
        @milestones = @roadmap.milestones

        render template: "houston/roadmaps/roadmaps/show_editable" if can?(:update, @roadmap)
      end


      def history
        authorize! :read, @roadmap
        @title = "#{@roadmap.name} History"

        @commits = @roadmap.commits.preload(:user)
        milestone_ids = @commits.each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |commit, map|
          commit.diffs.each do |diff|
            map[diff.fetch("milestone_type", "Milestone")].push(diff.fetch("milestone_id"))
          end
        end

        @milestones = []
        @milestones.concat Milestone.where(id: milestone_ids["Milestone"]).preload(:project) if milestone_ids.key?("Milestone")
        @milestones.concat Goal.where(id: milestone_ids["Goal"]).preload(:project) if milestone_ids.key?("Goal")

        @commit_id = params.fetch(:commit_id, @commits.last.id).to_i

        @markers = Houston::Roadmaps.config.markers
      end


      def play
        authorize! :read, @roadmap
        @title = "#{@roadmap.name} History"
        @start = Date.parse params[:start]
        @end = Date.parse params[:end]
        except = params.key?(:except) ? params[:except].split(",") : []

        @commits = @roadmap.commits.preload(:user)
        milestone_ids = @commits.flat_map { |commit| commit.diffs.flat_map { |diff| diff["milestone_id"] } }.uniq
        @milestones = Milestone.where(id: milestone_ids).preload(:project)

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
        @roadmap = Roadmap.preload(:commits).find params[:id]
      end

    end
  end
end
