class Roadmap.ThumbnailRoadmapView
  today: new Date()

  constructor: (options)->
    @milestones = options.milestones
    @parent = options.parent
    @viewport = options.viewport
    @showToday = options.showToday
    @markers = options.markers
    @milestones.bind 'add', @update, @
    @milestones.bind 'remove', @update, @
    @milestones.bind 'change', @update, @
    @milestones.bind 'reset', @update, @
    $(window).resize (e)=>
      @updateWindow() if e.target is window

  render: ->
    @height = 46
    @graphHeight = @height - 18

    el = @parent.append('div')
      .attr('style', "position: relative; height: #{@height}px;")

    svg = el.append('svg')
        .attr('height', @height)
        .attr('class', 'roadmap-thumbnail')
      .append('g')
        .attr('transform', "translate(0,0)")

    @roadmap = svg.append('g')
      .attr('class', 'roadmap-bands')

    @viewer = el.selectAll('.roadmap-thumbnail-viewer')
      .data([@viewport])

    view = @
    @viewer.enter()
      .append('div')
        .attr('class', 'roadmap-thumbnail-viewer')
        .attr('style', "top: 1px; height: #{@height - 2}px; left: 1px;")
        .each ->
          $(@).draggable
            axis: 'x'
            containment: 'parent'
            drag: (e, ui)->
              start = view.x.invert(ui.position.left)
              offset = start - view.viewport.get('start')
              end = new Date(+view.viewport.get('end') + offset)
              view.viewport.set(start: start, end: end)
          .resizable
            handles: 'e'
            containment: 'parent'
            resize: (e, ui)->
              end = view.x.invert(ui.position.left + ui.size.width)
              view.viewport.set(end: end)

    @xAxis = svg.append('g')
      .attr('class', 'x axis')
      .attr('transform', "translate(0,#{@graphHeight})")

    @updateWindow()

  updateWindow: ->
    width = $('#roadmap').width() || 960
    return if @width is width
    @width = width

    @parent.select('.roadmap-thumbnail').transition(150).attr('width', @width)

    @update()

  update: ->
    visibleMilestones = _.select @milestones.toJSON(), (m)-> m.startDate and m.endDate

    if visibleMilestones.length > 0
      @startDate = 3.weeks().before d3.min(visibleMilestones, (m)-> m.startDate)
      @endDate = 12.weeks().after d3.max(visibleMilestones, (m)-> m.endDate)
    else
      @startDate = 3.weeks().ago()
      @endDate = 12.weeks().fromNow()

    @startDate = @viewport.get('start') if @viewport.get('start') < @startDate
    @endDate = @viewport.get('end') if @viewport.get('end') > @endDate

    @x = d3.time.scale()
      .domain([@startDate, @endDate])
      .range([0, @width])
    timeline = d3.svg.axis()
      .scale(@x)
      .orient('bottom')
      .innerTickSize(4)
    @xAxis.transition(150).call(timeline)

    @viewer.attr('style', (viewport)=> "top: 1px; height: #{@height - 2}px; left: #{@x(viewport.get('start'))}px; width: #{@x(viewport.get('end')) - @x(viewport.get('start'))}px;")



    milestoneBands = d3.nest()
      .key (milestone)-> milestone.band
      .entries(visibleMilestones)

    bands = @roadmap.selectAll('.roadmap-thumbnail-band')
      .data(milestoneBands, (band)-> band.key)

    bands.enter()
      .append('g')
        .attr('class', 'roadmap-thumbnail-band')
        .attr('transform', (d, i)-> "translate(0,#{2 + i * 6})")

    bands.exit().remove()

    milestones = bands.selectAll('.roadmap-thumbnail-milestone')
      .data(((band)-> band.values), (milestone)-> milestone.cid)

    # update
    milestones
      .attr 'class', (milestone)->
        css = ['roadmap-thumbnail-milestone']
        css.push 'completed' if milestone.completed
        css.join(' ')
      .transition(150)
        .attr('height', (milestone)-> milestone.lanes * 6 - 1)
        .attr('width', (milestone)=> @x(milestone.endDate) - @x(milestone.startDate))
        .attr('x', (milestone)=> @x(milestone.startDate))

    # enter
    milestones.enter().append('rect')
      .attr('rx', 1)
      .attr('ry', 1)
      .attr('height', (milestone)-> milestone.lanes * 6 - 1)
      .attr('width', (milestone)=> @x(milestone.endDate) - @x(milestone.startDate))
      .attr('x', (milestone)=> @x(milestone.startDate))
      .attr 'class', (milestone)->
        css = ['roadmap-thumbnail-milestone']
        css.push 'completed' if milestone.completed
        css.join(' ')

    # exit
    milestones.exit().remove()


    if @showToday
      todayLine = @roadmap.selectAll('.thumbnail-roadmap-today')
        .data([@today])

      todayLine.enter()
        .append('rect')
          .attr('class', 'thumbnail-roadmap-today')
          .attr('height', @graphHeight - 1)
          .attr('width', 1)
          .attr('x', (date)=> @x(date))
          .attr('y', 1)

      todayLine
        .attr('x', (date)=> @x(date))



    markers = @roadmap.selectAll('.thumbnail-roadmap-marker')
      .data(@markers)

    markers.enter()
      .append('rect')
        .attr('class', 'thumbnail-roadmap-marker')
        .attr('height', @graphHeight - 1)
        .attr('width', 1)
        .attr('x', ({date})=> @x(date))
        .attr('y', 1)

    markers
      .attr('x', ({date})=> @x(date))

    markers.exit().remove()
