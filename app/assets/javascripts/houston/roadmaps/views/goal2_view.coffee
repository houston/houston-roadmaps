class @Goal2View extends Backbone.View
  template: HandlebarsTemplates['houston/roadmaps/goal/show']

  events:
    'click a.add-todolist': 'addTodoList'
    'click a.delete-todolist': 'deleteTodoList'

  initialize: (options)->
    @goal = options.goal
    @todoLists = new TodoLists(@goal.todoLists)
    @unattachedTodoLists = options.unattachedTodoLists
    @connectableAccounts = options.connectableAccounts
    @todoLists.on("add", _.bind(@render, @))
    @todoLists.on("remove", _.bind(@render, @))

  render: ->
    todoLists = @todoLists.toJSON()
    attachedIds = _.map todoLists, (todoList)-> todoList.id
    newTodoLists = _.reject @unattachedTodoLists, (todoList)-> attachedIds.indexOf(todoList.id) >= 0
    @$el.html @template
      todoLists: todoLists
      unattachedTodoLists: newTodoLists
      connectableAccounts: @connectableAccounts
    @

  addTodoList: (e)->
    e.preventDefault();
    $a = $(e.target)
    provider = $a.attr('data-provider')
    name = $a.attr('data-name')
    id = +$a.attr('data-id')
    result = @todoLists.create
      id: id
      goal_id: @goal.id
      name: name
    ,
      wait: true
      url: "/roadmap/goals/#{@goal.id}/todolists/#{id}"

  deleteTodoList: (e)->
    e.preventDefault();
    $a = $(e.target)
    id = +$a.attr('data-id')
    todoList = @todoLists.get(id)
    return unless todoList
    todoList.destroy
      wait: true
      url: "/roadmap/goals/#{@goal.id}/todolists/#{id}"
