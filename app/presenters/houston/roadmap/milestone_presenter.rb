class Houston::Roadmap::MilestonePresenter
  
  def initialize(milestones)
    @milestones = OneOrMany.new(milestones)
  end
  
  def as_json(*args)
    @milestones.map(&method(:to_hash))
  end
  
  def to_hash(milestone)
    { id: milestone.id,
      name: milestone.name,
      tickets: milestone.tickets_count,
      position: milestone.position }
  end
  
end
