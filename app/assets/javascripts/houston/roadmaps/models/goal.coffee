class Roadmaps.Goal extends Backbone.Model
  urlRoot: '/roadmap/milestones'



class Roadmaps.Goals extends Backbone.Collection
  model: Roadmaps.Goal

  outsideOf: (milestones) ->
    ids = _(milestones.pluck('milestoneId'))
    new Roadmaps.Goals @reject (goal) -> ids.include(goal.id)
