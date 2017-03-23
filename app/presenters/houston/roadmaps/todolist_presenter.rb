class Houston::Roadmaps::TodolistPresenter

  def initialize(todolists)
    @todolists = OneOrMany.new(todolists)
  end

  def as_json(*args)
    @todolists.map(&method(:to_hash))
  end

  def to_hash(todolist)
    { id: todolist.id,
      remoteId: todolist.remote_id,
      name: todolist.name,
      items: todolist.items_count,
      completedItems: todolist.completed_items_count }
  end

end
