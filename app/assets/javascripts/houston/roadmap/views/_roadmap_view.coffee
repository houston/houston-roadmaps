class Roadmap.RoadmapView
  today: new Date()
  
  constructor: (@milestones, options={})->
    @showToday = options.showToday ? true
    @showThumbnail = options.showThumbnail ? true
    @showWeekends = options.showWeekends ? false
    @linkMilestones = options.linkMilestones ? false
    @showProgress = options.showProgress ? false
    @viewport = options.viewport ? @defaultViewport()
    @viewport.bind 'change', @updateViewport, @
    @height = 24
    @markers = options.markers ? []
    for marker in @markers
      marker.date = App.serverDateFormat.parse(marker.date)
    @milestones.bind 'add', @update, @
    @milestones.bind 'change', @update, @
    @milestones.bind 'remove', @update, @
    @milestones.bind 'reset', @reset, @
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
        markers: @markers
        showToday: @showToday
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
  
  reset: ->
    window.setTimeout _.bind(@updateViewport, @)
  
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
    transition = options?.transition ? true
    view = @
    @today = new Date()
    
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
      
      update = if transition then weeks.transition(150) else weeks
      update
        .attr('style', (date)=> "left: #{@x(date)}px; width: #{@x(2.days().after(date)) - @x(date)}px;")
      
      weeks.exit().remove()
    
    
    
    milestones = bands.selectAll('.roadmap-milestone')
      .data(((band)-> band.milestones), (milestone)-> milestone.cid)
    
    newMilestones = if @linkMilestones
      milestones.enter().append('a')
        .attr('href', (milestone)-> "/roadmap/milestones/#{milestone.id}")
    else
      milestones.enter().append('div')
    
    if @showProgress
      newMilestones.append('div')
        .attr('class', 'roadmap-milestone-progress')
    
    newMilestones
      .attr 'style', (milestone)=>
        [ "left: #{@x(milestone.startDate)}px",
          "width: #{@x(milestone.endDate) - @x(milestone.startDate)}px",
          "height: #{milestone.lanes * 38 - 8}px" ].join('; ')
      .attr('class', 'roadmap-milestone')
      .attr('data-cid', (milestone)-> milestone.cid)
      .each -> view.initializeMilestone.apply(view, [@])
      
      # Put the milestone name into a span so that Midori can render it correctly
      .append('span')
        .text((milestone)-> milestone.name)
    
    update = if transition then milestones.transition(150) else milestones
    update
      .attr 'class', (milestone)=>
        classes = ['roadmap-milestone']
        classes.push(if milestone.locked then 'locked' else 'unlocked')
        classes.push(if milestone.completed then 'completed' else 'uncompleted')
        if milestone.startDate > @today
          classes.push 'upcoming'
        else if milestone.endDate < @today
          classes.push 'past'
        else
          classes.push 'active'
        classes.join(' ')
      .attr 'style', (milestone)=>
        [ "left: #{@x(milestone.startDate)}px",
          "width: #{@x(milestone.endDate) - @x(milestone.startDate)}px",
          "height: #{milestone.lanes * 38 - 8}px" ].join('; ')
      .select('.roadmap-milestone-progress')
        .attr 'style', (milestone)->
          return "width: 0" if milestone.tickets is 0
          "width: #{milestone.percentComplete * 100}%"
    
    milestones.exit().remove()
    
    
    
    if @showToday
      todayLine = @roadmap.selectAll('.roadmap-today')
        .data([@today])
      
      todayLine.enter()
        .append('div')
          .attr('class', 'roadmap-today')
          .attr('style', (date)=> "left: #{@x(date)}px;")
      
      update = if transition then todayLine.transition(150) else todayLine
      update
        .attr('style', (date)=> "left: #{@x(date)}px;")
    
    
    
    markers = @roadmap.selectAll('.roadmap-marker')
      .data(@markers)
    
    markers.enter()
      .append('div')
        .attr('class', 'roadmap-marker')
        .attr('style', ({date})=> "left: #{@x(date)}px;")
    
    update = if transition then markers.transition(150) else markers
    update
      .attr('style', ({date})=> "left: #{@x(date)}px;")
  
    markers.exit().remove()
  
  groupMilestonesIntoBands: ->
    milestoneBands = {}
    milestones = (@toJSON(milestone) for milestone in @milestones.models)
    for milestone in milestones when milestone.startDate and milestone.endDate
      key = "#{milestone.projectId}-#{milestone.band}"
      (milestoneBands[key] ||=
        key: key
        projectId: milestone.projectId
        color: milestone.projectColor
        number: milestone.band
        milestones: []).milestones.push(milestone)
    
    _.sortBy(_.values(milestoneBands), 'projectId')
  
  toJSON: (milestone)->
    json = milestone.toJSON()
    json.cid = milestone.cid
    json
  
  initializeBand: ->
  initializeMilestone: ->
