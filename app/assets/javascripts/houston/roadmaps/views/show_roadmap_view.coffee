class Roadmaps.ShowRoadmapView extends Backbone.View

  initialize: ->
    @setMilestones @options.milestones

  setMilestones: (@milestones)->
    @roadmap = new Roadmaps.RoadmapView(@milestones, @options)
    @

  render: ->
    @roadmap.render()
    @
