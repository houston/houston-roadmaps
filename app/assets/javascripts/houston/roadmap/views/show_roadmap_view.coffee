class Roadmap.ShowRoadmapView extends Backbone.View
  
  initialize: ->
    @setMilestones @options.milestones
  
  setMilestones: (@milestones)->
    @roadmap = new Roadmap.RoadmapView(@milestones, @options)
    @
  
  render: ->
    @roadmap.render()
    @
