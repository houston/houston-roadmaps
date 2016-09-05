class Roadmaps.ProjectGoalsView extends Neat.CollectionEditor
  renderNewGoalModal: HandlebarsTemplates['houston/roadmaps/goals/new']
  resource: 'goals'
  viewPath: 'houston/roadmaps/goals'
  pageSize: Infinity

  initialize: (options)->
    @options = options
    @project = @options.project
    @can = @options.can
    @goals = @collection = @options.goals
    super

    $('#new_goal_button').click (e) =>
      @newGoal(e)



  render: ->
    super
    $('.table-sortable').tablesorter()
    @



  newGoal: (e)->
    e.preventDefault() if e
    goal = new Roadmaps.Goal
      projectId: @project.id
    @goals.unshift goal
    @edit @views[0]
