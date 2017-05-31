class Roadmaps.GanttChart
  today: new Date()

  constructor: (@milestones, options={})->
    @el = options.el
    @selector = options.selector ? '#roadmap'
    @showToday = options.showToday ? true
    @showThumbnail = options.showThumbnail ? true
    @showWeekends = options.showWeekends ? false
    @linkMilestones = options.linkMilestones ? false
    @showProgress = options.showProgress ? false
    @bandHeight = options.bandHeight ? 30
    @bandMargin = options.bandMargin ? 8
    @transitionDuration = options.transition ? 150
    @roadmapId = options.roadmapId
    @viewport = options.viewport ? @defaultViewport()
    @viewport.bind 'change', @updateViewport, @
    @height = 24
    @markers = options.markers ? []
    for marker in @markers
      marker.date = App.parseDate(marker.date).endOfDay()
    @milestones.bind 'add', @update, @
    @milestones.bind 'change', @update, @
    @milestones.bind 'remove', @update, @
    @milestones.bind 'reset', @update, @
    $(window).resize (e)=>
      @updateWindow() if e.target is window

  defaultViewport: ->
    new Roadmaps.Viewport
      start: 3.weeks().before(@today)
      end: 6.months().after(3.weeks().before(@today))

  render: ->
    @el = $(@selector)[0] unless @el
    @$el = $(@el)

    if @showThumbnail
      @thumbnail = new Roadmaps.ThumbnailGanttChart
        milestones: @milestones
        markers: @markers
        showToday: @showToday
        viewport: @viewport
        parent: d3.select(@el)
      @thumbnail.render()

    @roadmap = d3.select(@el)
      .append('div')
        .attr('class', 'roadmap-bands')

    svg = @roadmap.append('svg')
        .attr('height', @height)
        .attr('class', 'roadmap-axis')
      .append('g')
        .attr('transform', "translate(0,0)")
    @xAxis = svg.append('g').attr('class', 'x axis')

    @updateWindow()

  updateWindow: ->
    width = @$el.width() || 960
    return if @width is width
    @width = width

    @roadmap.select('svg').transition().duration(@transitionDuration).attr('width', @width)

    @x = d3.time.scale()
      .domain(@viewport.domain())
      .range([0, @width])
    timeline = d3.svg.axis()
      .scale(@x)
      .orient('bottom')
    @xAxis.transition().duration(@transitionDuration).call(timeline)

    @update(transition: true)

  updateViewport: ->
    @x = d3.time.scale()
      .domain(@viewport.domain())
      .range([0, @width])
    timeline = d3.svg.axis()
      .scale(@x)
      .orient('bottom')
    @xAxis.call(timeline)

    @update(transition: false)

  update: (options)->
    transition = options?.transition ? true
    view = @
    @today = new Date()

    bands = @roadmap.selectAll('.roadmap-band')
      .data(@groupMilestonesIntoBands(), (band)-> band.key)

    bands.enter()
      .insert('div')
        .attr('class', (band)-> "roadmap-band")
        .attr('style', (date)=> "height: #{@bandHeight}px; margin: #{@bandMargin}px 0;")
        .attr('data-band', (band)-> band.number)
        .each -> view.initializeBand.apply(view, [@])

    bands.exit().remove()



    if @showWeekends
      weeks = @roadmap.selectAll('.roadmap-weekend')
        .data(d3.time.saturdays(@x.domain()...), (date)-> date)

      weeks.enter().append('div')
        .attr('class', 'roadmap-weekend')
        .attr('style', (date)=> "left: #{@x(date)}px; width: #{@x(2.days().after(date)) - @x(date)}px;")

      update = if transition then weeks.transition().duration(@transitionDuration) else weeks
      update
        .attr('style', (date)=> "left: #{@x(date)}px; width: #{@x(2.days().after(date)) - @x(date)}px;")

      weeks.exit().remove()



    milestones = bands.selectAll('.roadmap-milestone')
      .data(((band)-> band.milestones), (milestone)-> milestone.cid)

    newMilestones = if @linkMilestones
      milestones.enter().append('a')
        .attr('href', _.bind(@urlForMilestone, @))
    else
      milestones.enter().append('div')

    if @showProgress
      newMilestones.append('div')
        .attr('class', 'roadmap-milestone-progress')

    newMilestones
      .attr 'style', (milestone)=>
        [ "left: #{@x(milestone.startDate)}px",
          "width: #{@x(milestone.endDate) - @x(milestone.startDate)}px",
          "height: #{milestone.lanes * (@bandHeight + @bandMargin) - @bandMargin}px" ].join('; ')
      .attr('class', 'roadmap-milestone')
      .attr('data-cid', (milestone)-> milestone.cid)
      .attr('data-milestone-id', (milestone)-> milestone.id)
      .attr('data-milestone-type', (milestone)-> milestone.type)
      .each -> view.initializeMilestone.apply(view, [@])

      # Put the milestone name into a span so that Midori can render it correctly
      .append('span')
        .attr('class', 'roadmap-milestone-name')
        .text((milestone)-> milestone.name)

    update = if transition then milestones.transition().duration(@transitionDuration) else milestones
    update
      .attr 'class', (milestone)=>
        classes = ['roadmap-milestone', milestone.projectColor]
        classes.push(if milestone.locked then 'locked' else 'unlocked')
        classes.push(if milestone.completed then 'completed' else 'uncompleted')
        classes.push('clickable') if @linkMilestones
        if milestone.startDate > @today
          classes.push 'upcoming'
        else if milestone.endDate < @today
          classes.push 'past'
        else
          classes.push 'active'
        classes.push 'active' if milestone.percentComplete > 0
        classes.join(' ')
      .attr 'style', (milestone)=>
        [ "left: #{@x(milestone.startDate)}px",
          "width: #{@x(milestone.endDate) - @x(milestone.startDate)}px",
          "height: #{milestone.lanes * (@bandHeight + @bandMargin) - @bandMargin}px" ].join('; ')
      .select('.roadmap-milestone-progress')
        .attr 'style', (milestone)->
          return "width: 0" if milestone.tickets is 0
          "width: #{milestone.percentComplete * 100}%"

    update.select('.roadmap-milestone-name')
      .text((milestone)-> milestone.name)

    milestones.exit().remove()



    if @showToday
      todayLine = @roadmap.selectAll('.roadmap-today')
        .data([@today])

      todayLine.enter()
        .append('div')
          .attr('class', 'roadmap-today')
          .attr('style', (date)=> "left: #{@x(date)}px;")

      update = if transition then todayLine.transition().duration(@transitionDuration) else todayLine
      update
        .attr('style', (date)=> "left: #{@x(date)}px;")



    markers = @roadmap.selectAll('.roadmap-marker')
      .data(@markers, (marker) -> marker.id)

    markers.enter()
      .append('div')
        .attr('class', 'roadmap-marker')
        .attr('style', ({date})=> "left: #{@x(date)}px;")

    update = if transition then markers.transition().duration(@transitionDuration) else markers
    update
      .attr('style', ({date})=> "left: #{@x(date)}px;")

    markers.exit().remove()

  groupMilestonesIntoBands: ->
    milestoneBands = {}
    milestones = (@toJSON(milestone) for milestone in @milestones.models)
    for milestone in milestones when milestone.startDate and milestone.endDate and !milestone.removed
      (milestoneBands[milestone.band] ||=
        key: milestone.band
        number: milestone.band
        milestones: []).milestones.push(milestone)
    _.values(milestoneBands)

  toJSON: (milestone)->
    json = milestone.toJSON()
    json.cid = milestone.id # Use `id` because the view is readonly
    json

  initializeBand: ->
  initializeMilestone: ->

  urlForMilestone: (milestone)->
    if @roadmapId
      "/roadmaps/#{@roadmapId}/#{inflect.pluralize(milestone.type).toLowerCase()}/#{milestone.id}"
    else
      "/roadmap/#{inflect.pluralize(milestone.type).toLowerCase()}/#{milestone.id}"
