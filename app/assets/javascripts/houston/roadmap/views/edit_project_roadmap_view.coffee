class Roadmap.EditProjectRoadmapView extends Neat.CollectionEditor
  resource: 'milestones'
  viewPath: 'houston/roadmap/milestones'
  sortedBy: null
  pageSize: Infinity
  
  events:
    'click #new_milestone': 'newMilestone'
    'submit #new_milestone_form': 'createMilestone'
    'click #cancel_new_milestone_button': 'resetNewMilestone'
  
  initialize: ->
    @projectId = @options.projectId
    @milestones = @collection = @options.milestones
    @roadmap = new Roadmap.RoadmapView(@milestones)
    super
  
  render: ->
    super
    @$el.find('#milestones').sortable
      placeholder: 'ui-state-highlight'
      update: _.bind(@saveSequence, @)
    @roadmap.render()
    @
  
  saveSequence: ->
    ids = $('.milestone').pluck('data-id')
    $.put "#{window.location.pathname}/order", {order: ids}
  
  newMilestone: ->
    $('#new_milestone').hide()
    $('#new_milestone_form').show()
    $('#new_milestone_name').select()
  
  createMilestone: (e)->
    e.preventDefault()
    $('#new_milestone_form').disable()
    attributes = 
      name: $('#new_milestone_name').val()
      projectId: @projectId
    @milestones.create attributes,
      wait: true
      success: (milestone)=>
        @resetNewMilestone()
      error: (milestone, jqXhr)=>
        $('#new_milestone_form').enable()
        console.log('error', arguments)
        alert(jqXhr.responseText)
  
  resetNewMilestone: ->
    $('#new_milestone').show()
    $('#new_milestone_form').enable().hide()
    $('#new_milestone_name').val('')

