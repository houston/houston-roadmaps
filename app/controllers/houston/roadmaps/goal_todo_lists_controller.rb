module Houston::Roadmaps
  class GoalTodoListsController < ApplicationController
    attr_reader :goal, :todolist

    before_action :authenticate_user!
    before_action :find_goal
    before_action :find_todolist

    def add
      authorize! :update, goal
      goal.todolists << todolist
      render json: Houston::Roadmaps::TodolistPresenter.new(todolist), status: :created
    end

    def remove
      authorize! :update, goal
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
