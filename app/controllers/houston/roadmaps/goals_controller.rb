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

      @connectable_accounts = %w{todoist}
      authorization = Todoist.for(current_user).granted.with_scope("data:read_write").first
      if authorization
        @connectable_accounts.delete "todoist"
        authorization.sync! unless authorization.synced?
        @unattached_todo_lists = authorization.todolists.map do |todolist|
          { id: todolist.id,
            name: todolist.name }
        end
      end
    end

  private

    def find_goal
      @goal = Goal.unscoped.find(params[:id])
    end

  end
end