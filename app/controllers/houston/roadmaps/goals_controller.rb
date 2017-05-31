module Houston::Roadmaps
  class GoalsController < ApplicationController
    before_action :authenticate_user!
    before_action :find_goal
    attr_reader :goal

    layout "houston/roadmaps/application"

    def show
      authorize! :read, goal
      @project = goal.project
      @title = "#{goal.name} • #{@project.name}"

      roadmap = Roadmap.find_by_id(params[:roadmap_id]) if params[:roadmap_id]
      @milestone = roadmap.milestones.find { |milestone| milestone["type"] == "Goal" && milestone["id"] == goal.id } if roadmap

      @connectable_accounts = %w{todoist}
      authorization = Todoist.for(current_user).granted.with_scope("data:read_write").first
      if authorization
        @connectable_accounts.delete "todoist"
        authorization.sync! unless authorization.synced?
        @unattached_todo_lists = authorization.todolists.map { |todolist| Houston::Roadmaps::TodolistPresenter.new(todolist) }
      end
    end

    def update
      authorize! :update, goal
      if goal.update_attributes(goal_attributes)
        render json: Houston::Roadmaps::GoalPresenter.new(goal)
      else
        render json: goal.errors, status: :unprocessable_entity
      end
    end

  private

    def find_goal
      @goal = Goal.unscoped.find(params[:id])
    end

    def goal_attributes
      params.pick(:name, :closed)
    end

  end
end
