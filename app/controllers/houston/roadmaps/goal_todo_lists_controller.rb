module Houston::Roadmaps
  class GoalTodoListsController < ApplicationController
    attr_reader :goal, :todolist

    before_action :authenticate_user!
    before_action :find_goal
    before_action :find_todolist

    def add
      goal.todolists << todolist
      render json: {}, status: :created
    end

    def remove
      goal.todolists.delete todolist
      render json: {}
    end

  private

    def find_goal
      @goal = Goal.find(params.require(:goal_id))
    end

    def find_todolist
      @todolist = TodoList.find(params.require(:id))
    end

  end
end
