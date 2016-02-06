class Roadmaps.ShowMilestoneView extends @TicketsView
  supportsSorting: false
  template: HandlebarsTemplates['houston/roadmaps/milestone/show']

  initialize: ->
    @milestone = @options.milestone
    @id = @milestone.id
    @projectTicketTracker = @options.projectTicketTracker
    @usesFeedback = @options.usesFeedback
    super

    @$el.on 'click', '#show_completed_tickets', _.bind(@toggleShowCompleted, @)

  render: ->
    tickets = for ticket in @tickets.models
      json = ticket.toJSON()
      json.estimatedEffortCompleted = ticket.estimatedEffortCompleted()
      json.estimatedEffort = ticket.estimatedEffort()
      json

    html = @template
      projectSlug: @project
      milestone: @milestone
      usesFeedback: @usesFeedback
      tickets: tickets
    @$el.html html

    complete = _.select(tickets, (ticket)-> !!ticket.closedAt).length / tickets.length
    if _.isNaN(complete)
      $('.milestone-progress').hide()
    else
      $('#milestone_progress').html(App.formatPercent complete)
      $('.milestone-progress').show()

    @renderBurndownChart(@tickets.models)
    @



  rerenderTickets: ->
    template = HandlebarsTemplates['houston/roadmaps/milestone/ticket']
    $tickets = @$el.find('#tickets')
    return @render() if $tickets.length is 0
    $tickets.empty()
    for ticket in @tickets.models
      json = ticket.toJSON()
      json.estimatedEffortCompleted = ticket.estimatedEffortCompleted()
      json.estimatedEffort = ticket.estimatedEffort()
      $tickets.append template(json)



  renderBurndownChart: (tickets)->

    # Sum progress by week;
    # Find the total amount of effort to accomplish
    progressBySprint = {}
    totalEffort = 0
    mostRecentDataPoint = 0
    for ticket in tickets
      effort = +ticket.estimatedEffort()
      if effort and ticket.get('firstReleaseAt')
        firstReleaseAt = App.parseDate(ticket.get('firstReleaseAt'))
        mostRecentDataPoint = +firstReleaseAt if mostRecentDataPoint < firstReleaseAt
        sprint = @getEndOfSprint(firstReleaseAt)
        progressBySprint[sprint] = (progressBySprint[sprint] || 0) + effort
      totalEffort += effort

    [firstSprint, lastSprint] = d3.extent(+date for date in _.keys(progressBySprint))

    # Start 1 week before the first progress was made
    # to show the original total effort of the milestone
    firstSprint = @prevSprint(firstSprint)

    # Transform into remaining effort by week:
    # Iterate by week in case there are some weeks
    # where no progress was made
    remainingEffort = totalEffort
    sprint = firstSprint
    data = []
    while sprint <= lastSprint
      remainingEffort -= (progressBySprint[sprint] || 0)
      data.push
        day: new Date(sprint)
        effort: Math.ceil(remainingEffort)
      sprint = @nextSprint(sprint)

    # If the most recent data point is for an incomplete
    # sprint, disregard it when calculating the regressions
    lastCompleteSprint = @getEndOfSprint(1.week().before(new Date()))
    if @truncateDate(mostRecentDataPoint) > lastCompleteSprint
      regAll   = @computeRegression(data.slice( 0, -1)) if data.length >= 6  # all time
      regLast3 = @computeRegression(data.slice(-5, -1)) if data.length >= 5  # last 3 weeks only
      regLast2 = @computeRegression(data.slice(-4, -1)) if data.length >= 4  # last 2 weeks only
    else
      regAll   = @computeRegression(data)               if data.length >= 5  # all time
      regLast3 = @computeRegression(data.slice(-4))     if data.length >= 4  # last 3 weeks only
      regLast2 = @computeRegression(data.slice(-3))     if data.length >= 3  # last 2 weeks only

    width = mostRecentDataPoint - firstSprint
    maxDate = @getEndOfSprint(mostRecentDataPoint + width)
    console.log 'earliestDataPoint', new Date(firstSprint)
    console.log 'mostRecentDataPoint', new Date(mostRecentDataPoint)
    console.log 'lastCompleteSprint', new Date(lastCompleteSprint)
    console.log "width: #{(width / Duration.DAY).toFixed(1)} days"

    console.log 'regAll', new Date(regAll.x2) if regAll
    console.log 'regLast3', new Date(regLast3.x2) if regLast3
    console.log 'regLast2', new Date(regLast2.x2) if regLast2

    # Widen the graph so that it includes the X intercept
    projections = []
    projections.push regAll.x2 if regAll
    projections.push regLast2.x2 if regLast2
    projections.push regLast3.x2 if regLast3
    sprints = (d.day for d in data)
    if projectedEnd = projections.max()
      lastSprint = @getEndOfSprint(projectedEnd)
      lastSprint = maxDate if lastSprint > maxDate
      sprint = _.last(sprints)
      while sprint < lastSprint
        sprint = @nextSprint(sprint)
        sprints.push(sprint)

    chart = new Houston.BurndownChart()
      .days((new Date(sprint) for sprint in sprints))
      .dateFormat(d3.time.format('%b %e'))
      .totalEffort(totalEffort)
      .addLine('completed', data)
    chart.addRegression('all', regAll) if regAll
    chart.addRegression('last-3', regLast3) if regLast3
    chart.addRegression('last-2', regLast2) if regLast2
    chart.render()

    insertLinebreaks = (d)->
      el = d3.select(this)
      words = el.text().split(/\s+/)
      el.text('')

      el.append('tspan').text(words[0]).attr('class', 'month')
      el.append('tspan').text(words[1]).attr('x', 0).attr('dy', '11').attr('class', 'day')

    svg = d3.select('#graph').select('svg')
    svg.selectAll('.x.axis text').each(insertLinebreaks)

  prevSprint: (timestamp)->
    1.week().before(new Date(timestamp)).getTime()

  nextSprint: (timestamp)->
    1.week().after(new Date(timestamp)).getTime()

  getEndOfSprint: (timestamp)->
    +@getNextFriday(new Date(timestamp))

  getNextFriday: (date)->
    wday = date.getDay() # 0-6 (0=Sunday)
    daysUntilFriday = 5 - wday # 5=Friday
    daysUntilFriday += 7 if daysUntilFriday < 0
    daysUntilFriday.days().after(date)

  truncateDate: (date)->
    date = new Date(date)
    date.setHours(0)
    date.setMinutes(0)
    date.setSeconds(0)
    date.setMilliseconds(0)
    +date

  computeRegression: (data)->
    # Compute the linear regression of the points
    # http://trentrichardson.com/2010/04/06/compute-linear-regressions-in-javascript/
    # http://dracoblue.net/dev/linear-least-squares-in-javascript/159/
    [sum_x, sum_y, sum_xx, sum_xy, n] = [0, 0, 0, 0, data.length]
    for d in data
      [_x, _y] = [+d.day, d.effort]
      sum_x += _x
      sum_y += _y
      sum_xx += _x * _x
      sum_xy += _x * _y
    m = (n*sum_xy - sum_x*sum_y) / (n*sum_xx - sum_x*sum_x)
    b = (sum_y - m*sum_x) / n

    # No progress is being made
    return null if m == 0

    # Find the X intercept
    [x0, y0] = [((0 - b) / m), 0]

    # Calculate the regression line
    x1: new Date(+data[0].day)
    x2: x0
    y1: new Date(b + m * +data[0].day)
    y2: y0



  toggleShowCompleted: (e)->
    $button = $(e.target)
    if $button.hasClass('active')
      $button.removeClass('btn-success')
      @$el.addClass('hide-completed')
    else
      $button.addClass('btn-success')
      @$el.removeClass('hide-completed')
