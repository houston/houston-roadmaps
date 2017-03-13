class Roadmaps.Goal extends Backbone.Model
  urlRoot: '/roadmap/milestones'



class Roadmaps.Goals extends Backbone.Collection
  model: Roadmaps.Goal

  outsideOf: (milestones) ->
    # TODO: use type as well
    ids = _(milestones.pluck('id'))
    new Roadmaps.Goals @reject (goal) -> ids.include(goal.id)
