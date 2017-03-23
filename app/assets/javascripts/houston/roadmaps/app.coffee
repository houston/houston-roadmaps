window.Roadmaps = {}
window.Neat.template = HandlebarsTemplates

window.Roadmaps.getMilestonesByCommit = (allMilestones, commits) ->
  milestonesByCommit = {}
  currentMilestones = []

  dup = (milestones)-> _.clone(milestone) for milestone in milestones

  for commit in commits
    for diff in commit.diffs
      id = diff.milestoneId
      type = diff.milestoneType ? "Milestone"
      switch diff.status
        when "added"
          milestone = _(allMilestones).findWhere(id: id, type: type)
          currentMilestones.push _.extend(diff.attributes, milestone) if milestone
        when "modified"
          milestone = _(currentMilestones).findWhere(id: id, type: type)
          milestone[attribute] = value for attribute, value of diff.attributes if milestone
        when "deleted"
          currentMilestones = _(currentMilestones).reject (milestone) -> milestone.id is id and milestone.type is type
        else
          throw "Unknown status: '#{diff.status}'"

    milestonesByCommit[commit.id] = dup(currentMilestones)

  milestonesByCommit
