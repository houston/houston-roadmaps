class Roadmap.RoadmapView
  today: new Date()
  
  constructor: (@milestones, options={})->
    @showToday = options.showToday ? true
    @showThumbnail = options.showThumbnail ? true
    @showWeekends = options.showWeekends ? false
    @viewport = options.viewport ? @defaultViewport()
    @viewport.bind 'change', @updateViewport, @
    @height = 24
    @milestones.bind 'add', @update, @
    @milestones.bind 'change', @update, @
    @milestones.bind 'reset', @update, @
    $(window).resize (e)=>
      @updateWindow() if e.target is window
  
  defaultViewport: ->
    new Roadmap.Viewport
      start: 3.weeks().before(@today)
      end: 6.months().after(3.weeks().before(@today))
  
  render: ->
    @$el = $('#roadmap')
    
    if @showThumbnail
      @thumbnail = new Roadmap.ThumbnailRoadmapView
        milestones: @milestones
        viewport: @viewport
        parent: d3.select('#roadmap')
      @thumbnail.render()
    
    @roadmap = d3.select('#roadmap')
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
    
    @roadmap.select('svg').transition(150).attr('width', @width)
    
    @x = d3.time.scale()
      .domain(@viewport.domain())
      .range([0, @width])
    timeline = d3.svg.axis()
      .scale(@x)
      .orient('bottom')
    @xAxis.transition(150).call(timeline)
    
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
    view = @
    
    bands = @roadmap.selectAll('.roadmap-band')
      .data(@groupMilestonesIntoBands(), (band)-> band.key)
    
    bands.enter()
      .append('div')
        .attr('class', (band)-> "roadmap-band #{band.color}")
        .attr('data-band', (band)-> band.number)
        .each -> view.initializeBand.apply(view, [@])
    
    bands.exit().remove()
    
    
    
    if @showWeekends
      weeks = @roadmap.selectAll('.roadmap-weekend')
        .data(d3.time.saturdays(@x.domain()...), (date)-> date)
      
      weeks.enter().append('div')
        .attr('class', 'roadmap-weekend')
        .attr('style', (date)=> "left: #{@x(date)}px; width: #{@x(2.days().after(date)) - @x(date)}px;")
      
      update = if options.transition then weeks.transition(150) else weeks
      update
        .attr('style', (date)=> "left: #{@x(date)}px; width: #{@x(2.days().after(date)) - @x(date)}px;")
      
      weeks.exit().remove()
    
    
    
    milestones = bands.selectAll('.roadmap-milestone')
      .data(((band)-> band.milestones), (milestone)-> milestone.id)
    
    milestones.enter().append('div')
      .attr('style', (milestone)=> "left: #{@x(milestone.startDate)}px; width: #{@x(milestone.endDate) - @x(milestone.startDate)}px;")
      .attr('class', 'roadmap-milestone')
      .attr('data-id', (milestone)-> milestone.id)
      .text((milestone)-> milestone.name)
      .each -> view.initializeMilestone.apply(view, [@])
    
    update = if options.transition then milestones.transition(150) else milestones
    update
      .attr('class', (milestone)=> "roadmap-milestone #{if milestone.locked then "locked" else "unlocked"}")
      .attr('style', (milestone)=> "left: #{@x(milestone.startDate)}px; width: #{@x(milestone.endDate) - @x(milestone.startDate)}px;")
    
    milestones.exit().remove()
    
    
    
    if @showToday
      today = @roadmap.selectAll('.roadmap-today')
        .data([@today])
      
      today.enter()
        .append('div')
          .attr('class', 'roadmap-today')
          .attr('style', (date)=> "left: #{@x(date)}px;")
      
      update = if options.transition then today.transition(150) else today
      update
        .attr('style', (date)=> "left: #{@x(date)}px;")
  
  groupMilestonesIntoBands: ->
    milestoneBands = {}
    for milestone in @milestones.toJSON() when milestone.startDate and milestone.endDate
      key = "#{milestone.projectId}-#{milestone.band}"
      (milestoneBands[key] ||=
        key: key
        projectId: milestone.projectId
        color: milestone.projectColor
        number: milestone.band
        milestones: []).milestones.push(milestone)
    
    _.values(milestoneBands)
  
  initializeBand: ->
  initializeMilestone: ->
