class Houston::Roadmaps::RoadmapMilestonePresenter

  def initialize(milestones)
    @milestones = milestones
  end

  def as_json(*args)
    @milestones.map(&method(:to_hash))
  end

  def to_hash(attributes)
    milestone = Milestone.unscope(where: :destroyed_at).find(attributes["id"])
    project = milestone.project
    { id: attributes["id"],
      milestoneId: attributes["id"], # <-- TODO: can the frontend just use `id`?
      name: attributes["name"],
      projectId: project.id,
      projectColor: project.color,
      band: attributes["band"],
      lanes: attributes["lanes"],
      startDate: attributes["start_date"],
      endDate: attributes["end_date"],

      percentComplete: percent_complete(attributes["id"]),
      completed: milestone.completed?, # <-- TODO: can we just derive this from percentComplete?
      removed: false } # <-- TODO: why `removed`? (milestone.destroyed_at.present?)
  end

private

  def percent_complete(milestone_id)
    percent_complete_by_ticket.fetch(milestone_id, 0)
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
    @milestone_ids ||= Array(@milestones.map { |attributes| attributes["id"] })
  end

end
