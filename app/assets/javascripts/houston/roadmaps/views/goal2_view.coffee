class @Goal2View extends Backbone.View
  template: HandlebarsTemplates['houston/roadmaps/goal/show']

  events:
    'click a.add-todolist': 'addTodoList'
    'click a.delete-todolist': 'deleteTodoList'
    'click #close_goal_button': 'closeGoal'
    'click #reopen_goal_button': 'reopenGoal'

  initialize: (options)->
    @goal = options.goal
    @showRegression = !@goal.get('completed') && !@goal.get('closed')
    @minDate = App.parseDate(options.minDate) if options.minDate
    @targetDate = App.parseDate(options.targetDate) if options.targetDate
    @todoLists = new TodoLists _.sortBy @goal.get('todoLists'), (tdl)->
      -tdl.completedItemsCount / tdl.itemsCount
    @unattachedTodoLists = options.unattachedTodoLists
    @connectableAccounts = options.connectableAccounts
    @goal.on("change", _.bind(@render, @))
    @todoLists.on("add", _.bind(@render, @))
    @todoLists.on("remove", _.bind(@render, @))

  render: ->
    todoLists = @todoLists.toJSON()
    attachedIds = _.map todoLists, (todoList)-> todoList.id
    newTodoLists = _.reject @unattachedTodoLists, (todoList)-> attachedIds.indexOf(todoList.id) >= 0
    @$el.html @template
      goal: @goal.toJSON()
      todoLists: todoLists
      unattachedTodoLists: newTodoLists
      connectableAccounts: @connectableAccounts

    for todoList in todoLists
      @renderProgress(todoList)

    items = []
    for todoList in todoLists
      items = items.concat(todoList.items)

    new Houston.BurndownChart()
      .snapTo((date)=> @nextMonday(date))
      .nextTick((date)=> @nextWeek(date))
      .dateFormat(d3.time.format('%b %e'))
      .minDate(@minDate)
      .addPipe(@targetDate)
      .data(items, regression: @showRegression, burnup: true)
      .render()

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
    e.preventDefault()
    $a = $(e.target)
    id = +$a.attr('data-id')
    todoList = @todoLists.get(id)
    return unless todoList
    todoList.destroy
      wait: true
      url: "/roadmap/goals/#{@goal.id}/todolists/#{id}"

  closeGoal: (e)->
    e.preventDefault()
    @goal.save
      closed: true
    , wait: true

  reopenGoal: (e)->
    e.preventDefault()
    @goal.save
      closed: false
    , wait: true

  renderProgress: (todoList)->
    $pie = $("#todolist_#{todoList.id} .progress-pie")

    completed = +todoList.completedItemsCount
    total = +todoList.itemsCount
    uncompleted = total - completed
    data = [completed, uncompleted]

    diameter = 28
    radius = diameter / 2
    thickness = 5
    width = diameter
    height = diameter

    if uncompleted is 0
      $pie.addClass("complete")
      thickness = radius
    else
      $pie.removeClass("complete")

    colors = ["#5db64c", "#e8e8e8"]

    arc = d3.svg.arc()
      .outerRadius(radius)
      .innerRadius(radius - thickness)

    pie = d3.layout.pie()
      .sort(null)
      .value((d) -> d)

    svg = d3.select($pie[0]).append("svg")
        .attr("width", width)
        .attr("height", height)
      .append("g")
        .attr("transform", "translate(#{width / 2},#{height / 2})")

    g = svg.selectAll(".arc")
        .data(pie(data))
      .enter().append("g")
        .attr("class", "arc");

    g.append("path")
      .attr("d", arc)
      .style("fill", (_, i)-> colors[i])



  nextWeek: (date)->
    1.week().after(date)

  nextMonday: (date)->
    return null unless date
    wday = date.getDay() # 0-6 (0=Sunday)
    daysUntilMonday = 1 - wday
    daysUntilMonday += 7 if daysUntilMonday < 0
    daysUntilMonday.days().after(date)
