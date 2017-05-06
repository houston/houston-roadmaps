class Houston.BurndownChart

  constructor: ->
    @_margin = {top: 40, right: 0, bottom: 24, left: 50}
    @_selector = '#graph'
    @_height = 260
    @$el = $(@_selector)
    @_totalEffort = 0
    @_lines = {}
    @_regressions = {}
    @_snapTo = (date)-> date
    $(window).resize (e)=>
      @render() if e.target is window

  margin: (@_margin)-> @
  height: (@_height)-> @
  selector: (@_selector)-> @$el = $(@_selector); @
  dateFormat: (@_dateFormat)-> @
  totalEffort: (@_totalEffort)-> @
  snapTo: (@_snapTo)-> @
  addLine: (slug, data)-> @_lines[slug] = data; @
  addRegression: (slug, data)-> @_regressions[slug] = @computeRegression(data); @

  render: ->
    width = @$el.width() || 960
    height = @_height
    graphWidth = width - @_margin.left - @_margin.right
    graphHeight = height - @_margin.top - @_margin.bottom

    totalEffort = @_totalEffort
    unless totalEffort
      for slug, data of @_lines
        # max(effort) will always be on the first day of a project
        totalEffort = data[0].effort if data[0] and data[0].effort > totalEffort

    formatDate = @_dateFormat || d3.time.format('%A')

    allDates = []
    for slug, data of @_lines
      for value in data
        allDates.push(value.day)
    for slug, value of @_regressions
      allDates.push(@_snapTo(value.x2))
    min = d3.min(allDates)
    max = d3.max(allDates)

    x = d3.scale.ordinal().rangePoints([0, graphWidth], 0.75).domain(allDates)
    y = d3.scale.linear().range([graphHeight, 0]).domain([0, totalEffort])
    rx = d3.scale.linear().range([x(min), x(max)]).domain([min, max])

    xAxis = d3.svg.axis()
      .scale(x)
      .orient('bottom')
      .tickFormat((d)=> formatDate(new Date(d)))

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
