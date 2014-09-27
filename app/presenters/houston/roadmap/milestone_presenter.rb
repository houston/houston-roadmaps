class Houston::Roadmap::MilestonePresenter
  
  def initialize(milestones)
    @milestones = OneOrMany.new(milestones)
  end
  
  def as_json(*args)
    @milestones.map(&method(:to_hash))
  end
  
  def to_hash(milestone)
    project = milestone.project
    { id: milestone.id,
      name: milestone.name,
      projectId: project.id,
      projectColor: project.color,
      tickets: milestone.tickets_count,
      ticketsCompleted: milestone.closed_tickets_count,
      completed: milestone.completed?,
      band: milestone.band,
      locked: milestone.locked?,
      startDate: milestone.start_date,
      endDate: milestone.end_date }
  end
  
end
