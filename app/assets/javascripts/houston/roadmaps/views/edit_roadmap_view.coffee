class Roadmaps.EditRoadmapView extends Backbone.View
  template: HandlebarsTemplates['houston/roadmaps/roadmap/show']
  renderGoal: HandlebarsTemplates['houston/roadmaps/roadmap/goal']

  initialize: (options)->
    @options = options
    super
    @roadmapId = @options.id
    @milestonesUrl = "/roadmaps/#{@roadmapId}/milestones"
    @milestones = @options.milestones
    @projects = @options.projects
    @goals = @options.goals

    $('#reset_roadmap').click _.bind(@reset, @)
    $('#save_roadmap').click _.bind(@save, @)


    @milestones.bind 'change', @milestoneChanged, @
    @milestones.bind 'add', @milestoneChanged, @
    @milestones.bind 'remove', @milestoneChanged, @

  render: ->
    @$el.html @template()
    @$goals = @$el.find('#goals')
    @$goals_view = @$el.find('#goals_view')
    @roadmap = new Roadmaps.EditGanttChart @milestones,
      removeMilestoneByDroppingOn: @$goals_view
      showWeekends: true
    @roadmap.createMilestone(_.bind(@createMilestone, @))
    @roadmap.render()
    @milestoneChanged()

    setTop = =>
      roadmapBottom = $('#roadmap').position().top + $('#roadmap').height() - 10
      @$goals_view.css(top: roadmapBottom)
    setTop()
    $(window).resize(setTop)
    addResizeListener $('#roadmap')[0], setTop

    @

  milestoneChanged: ->
    @indicateIfRoadmapHasChanged()
    @renderGoals()

  indicateIfRoadmapHasChanged: ->
    @$el.find('.buttons button')
      .prop 'disabled', @milestones.changes().length is 0

  renderGoals: ->
    html = ""
    @goals.outsideOf(@milestones.unremoved()).each (goal) =>
      html += @renderGoal goal.toJSON()
    @$goals.html(html)

    @roadmap.dragFrom @$goals.find('.goal'), @goals
    @



  createMilestone: (attributes, callback)->
    $modal = $(HandlebarsTemplates["houston/roadmaps/milestone/new"](
      projects: @projects
    )).modal()
    $modal.find("#create_milestone_button").click (e) =>
      e.preventDefault()
      attributes.name = $modal.find("#milestone_name").val()
      attributes.projectId = +$modal.find("#milestone_project_id").val()
      project = _.findWhere(@projects, id: attributes.projectId)
      attributes.projectColor = project.color
      attributes.projectName = project.name
      attributes.tickets = 0
      attributes.ticketsCompleted = 0
      attributes.locked = false
      attributes.completed = false
      milestone = new Roadmaps.Milestone(attributes)
      @milestones.add(milestone)
      $modal.modal "hide"
    $modal.on 'hidden', ->
      $modal.remove()
      callback()
    $modal.find("#milestone_name").focus()

  reset: (e)->
    e.preventDefault()
    @milestones.revert()

  save: (e)->
    e.preventDefault()
    if message = prompt('Commit message:')
      $buttons = $('#reset_roadmap, #save_roadmap')
      changes = @milestones.changes()
      $buttons.prop('disabled', true)
      $.put(@milestonesUrl,
        roadmap: changes
        message: message)
        .success =>
          $buttons.prop('disabled', false)
          @milestones.url = @milestonesUrl
          @milestones.fetch
            parse: true
            wait: true
        .error (response)->
          $buttons.prop('disabled', false)
          errors = Errors.fromResponse(response)
          errors.renderToAlert()
