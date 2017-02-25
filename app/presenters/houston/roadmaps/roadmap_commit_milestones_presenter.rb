class Houston::Roadmaps::RoadmapCommitMilestonesPresenter

  def initialize(milestones)
    @milestones = milestones
  end

  def as_json(*args)
    @milestones.map(&method(:to_hash))
  end

  def to_hash(milestone)
    { id: milestone.id,
      milestoneId: milestone.id,
      name: milestone.name,
      projectId: milestone.project.id,
      projectColor: milestone.project.color }
  end

end
