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
        markers: @options.markers
      .createMilestone(_.bind(@createMilestone, @))
    @milestones.bind 'change', @indicateIfRoadmapHasChanged, @
    @milestones.bind 'add', @indicateIfRoadmapHasChanged, @
    @milestones.bind 'remove', @indicateIfRoadmapHasChanged, @
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
      attributes.tickets = 0
      attributes.ticketsCompleted = 0
      attributes.locked = false
      attributes.completed = false
      milestone = new Roadmap.Milestone(attributes)
      @milestones.add(milestone)
      callback()
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
          @milestones.url = "/roadmap/by_project/#{@projectSlug}"
          @milestones.fetch(reset: true, parse: true)
        .error (response)->
          $buttons.prop('disabled', false)
          errors = Errors.fromResponse(response)
          errors.renderToAlert()
