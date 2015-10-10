class Houston::Roadmap::MilestoneApiPresenter

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
      projectName: project.name,
      projectSlug: project.slug,
      tickets: milestone.tickets.map { |ticket| {
        id: ticket.id,
        number: ticket.number,
        summary: ticket.summary
      } },
      startDate: milestone.start_date,
      endDate: milestone.end_date }
  end

end
