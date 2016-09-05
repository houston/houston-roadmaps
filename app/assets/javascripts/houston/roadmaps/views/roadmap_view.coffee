class Roadmaps.RoadmapView extends Backbone.View

  initialize: (options)->
    @options = options
    @setMilestones @options.milestones

  setMilestones: (@milestones)->
    @roadmap = new Roadmaps.GanttChart(@milestones, @options)
    @

  render: ->
    @roadmap.render()
    @
