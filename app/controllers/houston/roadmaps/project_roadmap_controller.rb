module Houston
  module Roadmaps
    class ProjectRoadmapController < ApplicationController
      layout "houston/roadmaps/application"


      def index
        authorize! :read, Milestone

        @milestones = Milestone.visible
        @markers = Houston::Roadmaps.config.markers
        @title = "Roadmap"
      end

      def dashboard
        if params.key?(:range)
          start_date, end_date = params[:range]
            .split(/\.{2,}/)
            .map { |date| Date.strptime(date, "%Y-%m-%d") }
          @range = start_date..end_date
        else
          today = Date.today
          @range = 6.months.before(today)..6.months.after(today)
        end

        @milestones = Milestone.during(@range)

        if params.key?(:projects)
          slugs = params[:projects].split(",")
          @milestones = @milestones
            .joins(:project)
            .where(Project.arel_table[:slug].in(slugs))
        end

        @show_today = params[:today] != "false"

        @title = "Roadmap"
        respond_to do |format|
          format.html { render layout: "houston/roadmaps/dashboard" }
          format.json { render json: {
            range: {start: @range.begin, end: @range.end},
            milestones: Houston::Roadmaps::MilestonePresenter.new(@milestones) } }
        end
      end


      def show
        @project = Project.find_by_slug!(params[:slug])
        @title = "Roadmap • #{@project.name}"

        authorize! :read, @project.milestones.build

        @milestones = @project.milestones.all
        @markers = Houston::Roadmaps.config.markers

        if request.format.json?
          render json: Houston::Roadmaps::MilestonePresenter.new(@milestones)
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
      rescue ActiveRecord::RecordInvalid
        render json: $!.record.errors, status: 422
      end


      def history
        @project = Project.find_by_slug!(params[:slug])
        authorize! :read, @project.milestones.build

        @commits = RoadmapCommit.where(project: @project).order(created_at: :desc)
        @commit_id = params[:commit_id].to_i

        @milestones = @project.milestones.unscope(where: :destroyed_at)
        @markers = Houston::Roadmaps.config.markers
      end


    end
  end
end
