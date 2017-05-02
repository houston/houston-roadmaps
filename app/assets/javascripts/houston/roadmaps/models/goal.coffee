class Roadmaps.Goal extends Backbone.Model
  urlRoot: '/roadmap/goals'



class Roadmaps.Goals extends Backbone.Collection
  model: Roadmaps.Goal

  outsideOf: (milestones) ->
    new Roadmaps.Goals @reject (goal) ->
      milestones.findWhere(id: goal.id, type: goal.get('type'))
