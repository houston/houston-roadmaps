class Roadmap.ShowProjectRoadmapView extends Backbone.View
  
  initialize: ->
    @projectId = @options.projectId
    @milestones = @options.milestones
    @template = HandlebarsTemplates['houston/roadmap/show']
    @roadmap = new Roadmap.RoadmapView(@milestones, @options)
    super
  
  render: ->
    @$el.html @template(milestones: @milestones.toJSON())
    @roadmap.render()
    @
