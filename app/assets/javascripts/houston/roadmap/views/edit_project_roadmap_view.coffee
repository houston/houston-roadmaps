class Roadmap.EditProjectRoadmapView extends Neat.CollectionEditor
  resource: 'milestones'
  viewPath: 'houston/roadmap/milestones'
  sortedBy: 'startDate'
  sortOrder: 'asc'
  pageSize: Infinity
  
  events:
    'click #show_completed_milestones': 'toggleShowCompleted'
    'click #reset_roadmap': 'reset'
    'click #save_roadmap': 'save'
  
  initialize: ->
    @projectId = @options.projectId
    @projectSlug = @options.projectSlug
    @projectColor = @options.projectColor
    @milestones = @collection = @options.milestones
    @roadmap = new Roadmap.EditRoadmapView @milestones,
        project: {id: @projectId, color: @projectColor}
        showWeekends: true
      .createMilestone(_.bind(@createMilestone, @))
    @milestones.bind 'change', _.bind(@indicateIfRoadmapHasChanged, @)
    super
  
  render: ->
    super
    @roadmap.render()
    @indicateIfRoadmapHasChanged()
    @
  
  indicateIfRoadmapHasChanged: ->
    @$el.find('.buttons button')
      .prop 'disabled', @milestones.changes().length is 0
  
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
  
  reset: (e)->
    e.preventDefault()
    @milestones.revert()
  
  save: (e)->
    e.preventDefault()
    if message = prompt('Commit message:')
      $buttons = $('#reset_roadmap, #save_roadmap')
      changes = @milestones.changes()
      $buttons.prop('disabled', true)
      console.log 'changes', JSON.stringify(changes)
      $.put("/roadmap/by_project/#{@projectSlug}",
        roadmap: changes
        message: message)
        .success =>
          $buttons.prop('disabled', false)
          @milestones.clearChangesSinceSave()
        .error (response)->
          $buttons.prop('disabled', false)
          errors = Errors.fromResponse(response)
          errors.renderToAlert()
