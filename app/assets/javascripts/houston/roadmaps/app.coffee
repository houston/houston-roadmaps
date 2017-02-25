window.Roadmaps = {}
window.Neat.template = HandlebarsTemplates

window.Roadmaps.getMilestonesByCommit = (allMilestones, commits) ->
  milestonesByCommit = {}
  currentMilestones = []

  dup = (milestones)-> _.clone(milestone) for milestone in milestones

  for commit in commits
    for diff in commit.diffs
      switch diff.status
        when "added"
          milestone = _(allMilestones).findWhere(id: diff.milestoneId)
          currentMilestones.push _.extend(diff.attributes, milestone) if milestone
        when "modified"
          milestone = _(currentMilestones).findWhere(id: diff.milestoneId)
          milestone[attribute] = value for attribute, value of diff.attributes if milestone
        when "deleted"
          currentMilestones = _(currentMilestones).reject (milestone) -> milestone.id is diff.milestoneId
        else
          throw "Unknown status: '#{diff.status}'"

    milestonesByCommit[commit.id] = dup(currentMilestones)
  milestonesByCommit
