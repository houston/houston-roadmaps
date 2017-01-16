class Houston::Roadmaps::MilestonePresenter

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
      roadmaps: milestone.roadmap_ids,
      projectId: project.id,
      projectColor: project.color,
      projectName: project.name,
      tickets: milestone.tickets_count,
      ticketsCompleted: milestone.closed_tickets_count,
      percentComplete: percent_complete(milestone),
      completed: milestone.completed?,
      locked: milestone.locked? || milestone.completed?,
      removed: milestone.destroyed_at.present? }
  end

private

  def percent_complete(milestone)
    percent_complete_by_ticket.fetch(milestone.id, 0)
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
        [ milestone_id.to_i,
          closed == "t" ? 1.0 : (completed_tasks.to_f / tasks.to_i) ] }
      .group_by { |(milestone_id, _)| milestone_id }
      .map { |(milestone_id, tickets)|
        [milestone_id, (tickets.sum { |(_, percent)| percent } / tickets.length)] }]
  end

  def milestone_ids
    @milestone_ids ||= Array(@milestones.map(&:id))
  end

end
