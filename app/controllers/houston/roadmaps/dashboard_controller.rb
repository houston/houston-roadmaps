module Houston
  module Roadmaps
    class DashboardController < ApplicationController
      layout "houston/roadmaps/dashboard"


      def show
        if params.key?(:range)
          start_date, end_date = params[:range]
            .split(/\.{2,}/)
            .map { |date| Date.strptime(date, "%Y-%m-%d") }
          @range = start_date..end_date
        else
          today = Date.today
          @range = 6.months.before(today)..6.months.after(today)
        end

        @milestones = RoadmapMilestone.during(@range).preload(:milestone => :project)
        @milestones = @milestones.where(roadmap_id: params[:roadmap_id]) if params.key?(:roadmap_id)

        @show_today = params[:today] != "false"

        @title = "Roadmap"
        respond_to do |format|
          format.html { render }
          format.json { render json: {
            range: {start: @range.begin, end: @range.end},
            milestones: Houston::Roadmaps::RoadmapMilestonePresenter.new(@milestones) } }
        end
      end


    end
  end
end
