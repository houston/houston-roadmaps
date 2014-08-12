class Roadmap.Milestone extends Backbone.Model
  urlRoot: '/roadmap/milestones'

class Roadmap.Milestones extends Backbone.Collection
  model: Roadmap.Milestone
  
  sorted: -> new Roadmap.Milestones(@sortBy (milestone)-> milestone.get('position'))
