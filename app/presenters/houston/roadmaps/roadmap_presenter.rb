class Houston::Roadmaps::RoadmapPresenter

  def initialize(roadmaps)
    @roadmaps = OneOrMany.new(roadmaps)
  end

  def as_json(*args)
    @roadmaps.map(&method(:to_hash))
  end

  def to_hash(roadmap)
    { id: roadmap.id,
      name: roadmap.name,
      teams: roadmap.teams.map { |team| {
        id: team.id,
        name: team.name } },
      projects: roadmap.projects.map { |project| {
        id: project.id,
        name: project.name,
        color: project.color } },
      milestones: present_milestones(roadmap.milestones) }
  end

private

  def present_milestones(milestones)
    milestones.map do |milestone|
      # TODO: optimize this: manually preload projects
      klass = milestone.fetch("type", "Milestone").constantize
      project = klass.unscope(where: :destroyed_at).find(milestone["id"]).project
      { id: milestone["id"],
        name: milestone["name"],
        projectId: project.id,
        projectColor: project.color,
        band: milestone["band"],
        lanes: milestone["lanes"],
        startDate: milestone["start_date"],
        endDate: milestone["end_date"] }
    end
  end

end
