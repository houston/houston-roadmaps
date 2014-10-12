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
      percentComplete: percent_complete(milestone),
      completed: milestone.completed?,
      band: milestone.band,
      locked: milestone.locked?,
      startDate: milestone.start_date,
      endDate: milestone.end_date }
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
        open_tasks.count,
        completed_tasks.count
      FROM tickets
      LEFT OUTER JOIN (
        SELECT ticket_id, COUNT(id) "count"
        FROM tasks
        GROUP BY ticket_id)
      AS open_tasks
        ON open_tasks.ticket_id=tickets.id
      LEFT OUTER JOIN (
        SELECT ticket_Id, COUNT(id) "count"
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
          completed_tasks.to_i + (closed == "t" ? 1 : 0),
          tasks.to_i + 1 ] }
      .group_by { |(milestone_id, _, _)| milestone_id }
      .map { |(milestone_id, set)|
        [milestone_id, 
          set.sum { |(_, completed_tasks, _)| completed_tasks }.to_f /
          set.sum { |(_, _, open_tasks)| open_tasks }] }]
  end
  
  def milestone_ids
    @milestone_ids ||= Array(@milestones.map(&:id))
  end
  
end
