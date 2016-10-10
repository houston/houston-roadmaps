class Houston::Roadmaps::RoadmapMilestonePresenter

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
      milestoneId: milestone.milestone_id,
      projectId: project.id,
      projectColor: project.color,
      percentComplete: percent_complete(milestone),
      completed: milestone.completed?,
      band: milestone.band,
      lanes: milestone.lanes,
      startDate: milestone.start_date,
      endDate: milestone.end_date,
      removed: milestone.destroyed_at.present? }
  end

private

  def percent_complete(milestone)
    percent_complete_by_ticket.fetch(milestone.milestone_id, 0)
  end

  def percent_complete_by_ticket
    @percent_complete_by_ticket ||= Hash[Milestone.connection.select_rows(<<-SQL)
      SELECT
        tickets.milestone_id,
        tickets.id,
        tickets.closed_at IS NOT NULL "closed",
        all_tasks.count,
        completed_tasks.count
      FROM tickets
      LEFT OUTER JOIN (
        SELECT ticket_id, COUNT(id) "count"
        FROM tasks
        GROUP BY ticket_id)
      AS all_tasks
        ON all_tasks.ticket_id=tickets.id
      LEFT OUTER JOIN (
        SELECT ticket_id, COUNT(id) "count"
        FROM tasks
        WHERE tasks.completed_at IS NOT NULL
        GROUP BY ticket_id)
      AS completed_tasks
        ON completed_tasks.ticket_id=tickets.id
      WHERE tickets.destroyed_at IS NULL
      AND tickets.milestone_id IN (#{milestone_ids.join(", ")})
    SQL
      .map { |milestone_id, _, closed, tasks, completed_tasks|
        [ milestone_id, (closed ? tasks : completed_tasks).to_f / tasks ] }
      .group_by { |(milestone_id, _)| milestone_id }
      .map { |(milestone_id, tickets)|
        [milestone_id, (tickets.sum { |(_, percent)| percent } / tickets.length)] }]
  end

  def milestone_ids
    @milestone_ids ||= Array(@milestones.map(&:milestone_id))
  end

end
