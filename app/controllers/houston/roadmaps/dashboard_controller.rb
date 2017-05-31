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

        @roadmap = Roadmap.preload(:commits).find(params[:roadmap_id])
        @milestones = @roadmap.milestones.find_all { |milestone| milestone["start_date"].to_date <= @range.end && milestone["end_date"].to_date >= @range.begin }

        @show_today = params[:today] != "false"

        @title = "#{@roadmap.name} • Roadmaps"
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
