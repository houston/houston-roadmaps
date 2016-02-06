class Roadmaps.ShowProjectRoadmapView extends Backbone.View

  events:
    'click #show_completed_milestones': 'toggleShowCompleted'

  initialize: ->
    @projectId = @options.projectId
    @milestones = @options.milestones
    @template = HandlebarsTemplates['houston/roadmaps/show']
    @roadmap = new Roadmaps.RoadmapView(@milestones, @options)
    super

  render: ->
    @$el.html @template(milestones: @milestones.toJSON())
    @roadmap.render()
    @



  toggleShowCompleted: (e)->
    $button = $(e.target)
    if $button.hasClass('active')
      $button.removeClass('btn-success')
      @$el.addClass('hide-completed')
    else
      $button.addClass('btn-success')
      @$el.removeClass('hide-completed')
