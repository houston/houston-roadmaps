class Roadmap.ShowRoadmapView extends Backbone.View
  
  initialize: ->
    @showToday = @options.showToday ? true
    @setMilestones @options.milestones
  
  setMilestones: (@milestones)->
    @roadmap = new Roadmap.RoadmapView(@milestones, showToday: @showToday)
    @
  
  render: ->
    @roadmap.render()
    @
