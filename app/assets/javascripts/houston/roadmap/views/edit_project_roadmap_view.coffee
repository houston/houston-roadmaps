class Roadmap.EditProjectRoadmapView extends Neat.CollectionEditor
  resource: 'milestones'
  viewPath: 'houston/roadmap/milestones'
  sortedBy: 'startDate'
  sortOrder: 'asc'
  pageSize: Infinity
  
  events:
    'click #show_completed_milestones': 'toggleShowCompleted'
  
  initialize: ->
    @projectId = @options.projectId
    @projectColor = @options.projectColor
    @milestones = @collection = @options.milestones
    @roadmap = new Roadmap.EditRoadmapView @milestones,
        project: {id: @projectId, color: @projectColor}
        showWeekends: true
      .createMilestone(_.bind(@createMilestone, @))
    super
  
  render: ->
    super
    @roadmap.render()
    @
  
  createMilestone: (attributes, callback)->
    attributes.projectId = @projectId
    if attributes.name = prompt('Name:')
      @milestones.create attributes,
        wait: true
        success: (milestone)=>
          callback()
        error: (milestone, jqXhr)=>
          callback()
          console.log('error', arguments)
          alert(jqXhr.responseText)
    else
      callback()
  
  
  
  toggleShowCompleted: (e)->
    $button = $(e.target)
    if $button.hasClass('active')
      $button.removeClass('btn-success')
      @$el.addClass('hide-completed')
    else
      $button.addClass('btn-success')
      @$el.removeClass('hide-completed')
