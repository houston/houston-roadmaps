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

        if params[:burndown] == "yes"
          goal_ids = @roadmap.milestones
            .find_all { |milestone| milestone["type"] == "Goal" }
            .map { |milestone| milestone["id"] }
          items = TodoListItem.joins(<<~SQL).where("goals_todo_lists.goal_id" => goal_ids)
            INNER JOIN goals_todo_lists ON todo_list_items.todolist_id=goals_todo_lists.todo_list_id
          SQL
          @tasks = items.with_destroyed.map { |item|
            { openedAt: item.created_at,
              deletedAt: item.destroyed_at,
              closedAt: item.completed_at,
              effort: 1 } }
        end

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
