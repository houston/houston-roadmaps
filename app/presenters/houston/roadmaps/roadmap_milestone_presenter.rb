class Houston::Roadmaps::RoadmapMilestonePresenter

  def initialize(milestones)
    @milestones = milestones
  end

  def as_json(*args)
    @milestones.map(&method(:to_hash))
  end

  def to_hash(attributes)
    milestone = attributes.fetch("type").constantize.unscope(where: :destroyed_at).find(attributes.fetch("id"))
    project = milestone.project
    { id: attributes["id"],
      type: attributes["type"],
      name: attributes["name"],
      projectId: project.id,
      projectColor: project.color,
      band: attributes["band"],
      lanes: attributes["lanes"],
      startDate: attributes["start_date"],
      endDate: attributes["end_date"],

      percentComplete: percent_complete(attributes.values_at("type", "id")),
      completed: completed?(attributes.values_at("type", "id")),
      removed: false } # <-- TODO: why `removed`? (milestone.destroyed_at.present?)
  end

private

  def percent_complete((type, id))
    fraction_complete_by.fetch(type).fetch(id, 0).to_f
  end

  def completed?((type, id))
    fraction_complete_by.fetch(type).fetch(id, 0) == 1
  end

  def fraction_complete_by
    @fraction_complete_by ||= {
      "Milestone" => fraction_complete_by_milestone,
      "Goal" => fraction_complete_by_goal
    }
  end

  def fraction_complete_by_milestone
    return {} if milestone_ids.empty?
    Hash[Milestone.connection.select_rows(<<-SQL)
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
        [milestone_id, Rational(tickets.sum { |(_, percent)| percent }, tickets.length)] }]
  end

  def milestone_ids
    @milestone_ids ||= Array(@milestones)
      .select { |attributes| attributes["type"] == "Milestone" }
      .map { |attributes| attributes["id"] }
  end

  def fraction_complete_by_goal
    return {} if goal_ids.empty?
    Hash[Goal.connection.select_rows(<<-SQL)
      SELECT
        goals.id,
        COALESCE(SUM(todo_lists.items_count), 0),
        COALESCE(SUM(todo_lists.completed_items_count), 0),
        (goals.completed_at IS NOT NULL)
      FROM goals
      LEFT JOIN goals_todo_lists ON goals_todo_lists.goal_id=goals.id
      LEFT JOIN todo_lists ON goals_todo_lists.todo_list_id=todo_lists.id
      WHERE goals.id IN (#{goal_ids.join(", ")})
      GROUP BY goals.id, goals.completed_at
    SQL
      .map { |goal_id, total, completed, closed| [goal_id, closed ? 1 : total.zero? ? 0 : Rational(completed, total)] }]
  end

  def goal_ids
    @goal_ids ||= Array(@milestones)
      .select { |attributes| attributes["type"] == "Goal" }
      .map { |attributes| attributes["id"] }
  end

end
