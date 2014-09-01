class Roadmap.RoadmapView
  
  constructor: (@milestones, options={})->
    @showToday = options.showToday ? true
    @today = new Date()
    @startDate = 3.weeks().before(@today)
    @endDate = 6.months().after(@startDate)
    @height = 24
    @milestones.bind 'change', @update, @
    @milestones.bind 'reset', @update, @
    $(window).resize (e)=>
      @updateWindow() if e.target is window
  
  render: ->
    @$el = $('#roadmap')
    @roadmap = d3.select('#roadmap')
    
    svg = @roadmap.append('svg')
        .attr('height', @height)
        .attr('class', 'roadmap-axis')
      .append('g')
        .attr('transform', "translate(0,0)")
    @xAxis = svg.append('g').attr('class', 'x axis')
    
    @updateWindow()
  
  widthOfMilestone: (milestone)->
    return null if !milestone.size or !milestone.units
    weeks = milestone.size
    weeks *= 4.3452380952381 if milestone.units == 'months'
    weeks
  
  updateWindow: ->
    width = @$el.width() || 960
    return if @width is width
    @width = width
    
    @roadmap.select('svg').transition(150).attr('width', @width)
    
    @x = d3.time.scale()
      .domain([@startDate, @endDate])
      .range([0, @width])
    timeline = d3.svg.axis()
      .scale(@x)
      .orient('bottom')
    @xAxis.transition(150).call(timeline)
    
    @update()
  
  update: ->
    certainty = (milestone)->
      return 'certainty-low' if milestone.units.startsWith('mo')
      'certainty-mid'
    
    view = @
    
    bands = @roadmap.selectAll('.roadmap-band')
      .data(@groupMilestonesIntoBands(), (band)-> band.key)
    
    bands.enter()
      .append('div')
        .attr('class', (band)-> "roadmap-band #{band.color}")
        .attr('data-band', (band)-> band.number)
        .each -> view.initializeBand.apply(view, [@])
    
    bands.exit().remove()
    
    milestones = bands.selectAll('.roadmap-milestone')
      .data(((band)-> band.milestones), (milestone)-> milestone.id)
    
    # update
    milestones
      .attr('class', (milestone)-> "roadmap-milestone #{certainty(milestone)}")
      .transition(150)
        .attr('style', (milestone)=> "left: #{@x(milestone.startDate)}px; width: #{@x(milestone.endDate) - @x(milestone.startDate)}px;")
    
    # enter
    milestones.enter().append('div')
      .attr('style', (milestone)=> "left: #{@x(milestone.startDate)}px; width: #{@x(milestone.endDate) - @x(milestone.startDate)}px;")
      .attr('class', (milestone)-> "roadmap-milestone #{certainty(milestone)}")
      .attr('data-id', (milestone)-> milestone.id)
      .text((milestone)-> milestone.name)
      .each -> view.initializeMilestone.apply(view, [@])
    
    # exit
    milestones.exit().remove()
    
    if @showToday
      @roadmap.selectAll('.roadmap-today')
        .data([@today])
        .enter()
          .append('div')
            .attr('class', 'roadmap-today')
            .attr('style', (date)=> "left: #{@x(date)}px;")
  
  groupMilestonesIntoBands: ->
    milestoneBands = {}
    for milestone in @milestones.sorted().toJSON() when @widthOfMilestone(milestone)
      milestone.startDate = @today unless milestone.startDate
      milestone.duration = @widthOfMilestone(milestone)
      milestone.endDate = milestone.duration.weeks().after(milestone.startDate)
      
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
