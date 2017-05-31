class Houston.BurndownChart

  constructor: ->
    @_margin = {top: 40, right: 0, bottom: 24, left: 50}
    @_selector = '#graph'
    @_height = 260
    @$el = $(@_selector)
    @_lines = {}
    @_regressions = {}
    @_pipes = []
    @_minDate = null
    @_snapTo = (date)-> date
    @_nextTick = (date)-> 1.day().after(date)
    @_dateFormat = d3.time.format('%A')
    $(window).resize (e)=>
      @render() if e.target is window

  margin: (@_margin)-> @
  height: (@_height)-> @
  selector: (@_selector)-> @$el = $(@_selector); @
  dateFormat: (@_dateFormat)-> @
  snapTo: (@_snapTo)-> @
  nextTick: (@_nextTick)-> @
  minDate: (@_minDate)-> @
  addPipe: (date)-> @_pipes.push(date); @
  data: (tasks, options={})->
    completed = @computeBurndown(tasks)

    if options.burnup
      allDates = (value.day for value in completed)
      total = @computeBurnup(tasks, allDates)
      total = (point for point in total when point.day >= @_minDate) if @_minDate
      @_lines["total"] = total

    completed = (point for point in completed when point.day >= @_minDate) if @_minDate
    @_lines["completed"] = completed

    if options.regression
      # If the most recent data point is for an incomplete
      # sprint, disregard it when calculating the regressions
      today = new Date()
      pastData = (point for point in completed when point.day < today)
      @addRegression('all',    pastData)           if pastData.length >= 5  # all time
      @addRegression('last-3', pastData.slice(-4)) if pastData.length >= 4  # last 3 weeks only

    @
  addRegression: (slug, data)->
    line = @computeRegression(data)
    @_regressions[slug] = line if line
    @

  render: ->
    width = @$el.width() || 960
    height = @_height
    graphWidth = width - @_margin.left - @_margin.right
    graphHeight = height - @_margin.top - @_margin.bottom

    # max(effort) will always be on the first day of a project
    totalEffort = @_lines["completed"][0]?.effort
    if @_lines["total"]
      totalEffort = Math.max(totalEffort, d3.max(@_lines["total"], (data)-> data.effort))
    return unless totalEffort

    allDates = []
    for slug, data of @_lines
      for value in data
        allDates.push(value.day)
    min = d3.min(allDates)
    max = d3.max(allDates)

    # Widen the graph to include the milestone's projected completion date
    for slug, value of @_regressions
      while max < value.x2
        max = @_nextTick(max)
        allDates.push max

    # Widen the graph to include all pipes
    for date in @_pipes
      while max < date
        max = @_nextTick(max)
        allDates.push max

    x = d3.scale.ordinal().rangePoints([0, graphWidth], 0.75).domain(allDates)
    y = d3.scale.linear().range([graphHeight, 0]).domain([0, totalEffort])
    rx = d3.scale.linear().range([x(min), x(max)]).domain([min, max])

    xAxis = d3.svg.axis()
      .scale(x)
      .orient('bottom')
      .tickFormat((d)=> @_dateFormat(new Date(d)))

    yAxis = d3.svg.axis()
      .scale(y)
      .orient('left')

    line = d3.svg.line()
      .interpolate('linear')
      .x((d)-> x(d.day))
      .y((d)-> y(d.effort))

    @$el.empty()
    svg = d3.select(@_selector).append('svg')
        .attr('width', width)
        .attr('height', height)
      .append('g')
        .attr('transform', "translate(#{@_margin.left},#{@_margin.top})")

    svg.append('g')
      .attr('class', 'x axis')
      .attr('transform', "translate(0,#{graphHeight})")
      .call(xAxis)

    svg.append('g')
        .attr('class', 'y axis')
        .call(yAxis)
      .append('text')
        .attr('transform', 'rotate(-90)')
        .attr('y', -45)
        .attr('x', 160 - height)
        .attr('dy', '.71em')
        .attr('class', 'legend')
        .style('text-anchor', 'end')
        .text('Points Remaining')



    for slug, data of @_regressions
      svg.append('line')
        .attr('class', "regression regression-#{slug}")
        .attr('x1', rx(data.x1))
        .attr('y1', y(data.y1))
        .attr('x2', rx(data.x2))
        .attr('y2', y(data.y2))



    for slug, data of @_lines
      svg.append('path')
        .attr('class', "line line-#{slug}")
        .attr('d', line(data))

      svg.selectAll("circle.circle-#{slug}")
        .data(data)
        .enter()
        .append('circle')
          .attr('class', "circle-#{slug}")
          .attr('r', 5)
          .attr('cx', (d)-> x(d.day))
          .attr('cy', (d)-> y(d.effort))

      svg.selectAll(".effort-remaining.effort-#{slug}")
        .data(data)
        .enter()
        .append('text')
          .text((d) -> d.effort)
          .attr('class', "effort-remaining effort-#{slug}")
          .attr('transform', (d)-> "translate(#{x(d.day) + 5.5}, #{y(d.effort) - 10}) rotate(-75)")



    for date in @_pipes
      svg.append('line')
        .attr('class', "line")
        .attr('x1', rx(date))
        .attr('x2', rx(date))
        .attr('y1', graphHeight)
        .attr('y2', 0)

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
    x2 = (0 - b) / m

    # Find the regression's starting effort
    y1 = m * +data[0].day + b

    # Calculate the regression line
    x1: data[0].day
    x2: new Date(x2)
    y1: y1
    y2: 0

  computeBurndown: (tasks)->
    # Sum progress by date
    # Find the total amount of effort to accomplish
    progressByTick = {}
    totalEffort = 0
    for task in tasks when task.effort and not task.deletedAt
      if task.closedAt
        tick = +@_snapTo(App.parseDate(task.closedAt))
        progressByTick[tick] = (progressByTick[tick] || 0) + task.effort
      totalEffort += task.effort

    [firstTick, lastTick] = d3.extent(new Date(+date) for date in _.keys(progressByTick))

    if @_minDate
      lastTick = @_minDate if @_minDate > lastTick
      firstTick = @_minDate if @_minDate < firstTick

    # Transform into remaining effort by week:
    # Iterate by week in case there are some weeks
    # where no progress was made
    remainingEffort = totalEffort
    tick = firstTick
    data = []
    while tick <= lastTick
      remainingEffort -= (progressByTick[+tick] || 0)
      data.push
        day: tick
        effort: Math.ceil(remainingEffort)
      tick = @_nextTick(tick)

    data

  computeBurnup: (tasks, dates)->
    for date in dates
      totalEffort = 0
      for task in tasks when task.effort
        continue if task.openedAt and App.parseDate(task.openedAt) > date
        continue if task.deletedAt and App.parseDate(task.deletedAt) < date
        totalEffort += task.effort

      day: date
      effort: Math.ceil(totalEffort)
