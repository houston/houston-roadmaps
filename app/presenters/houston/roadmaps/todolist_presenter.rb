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
      items: todolist.items.with_destroyed.map { |item| {
        openedAt: item.created_at,
        deletedAt: item.destroyed_at,
        closedAt: item.completed_at,
        effort: 1 } },
      itemsCount: todolist.items_count,
      completedItemsCount: todolist.completed_items_count }
  end

end
