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
      band: milestone.band,
      size: milestone.size,
      units: milestone.units,
      startDate: milestone.start_date,
      position: milestone.position }
  end
  
end
