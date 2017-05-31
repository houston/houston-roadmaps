class Houston::Roadmaps::GoalPresenter

  def initialize(goals)
    @goals = OneOrMany.new(goals)
  end

  def as_json(*args)
    @goals.map(&method(:to_hash))
  end

  def to_hash(goal)
    { id: goal.id,
      name: goal.name,
      closed: goal.closed?,
      completed: goal.todolists.any? && goal.todolists.all?(&:completed?),
      todoLists: goal.todolists.map { |todolist| Houston::Roadmaps::TodolistPresenter.new(todolist) } }
  end

end
