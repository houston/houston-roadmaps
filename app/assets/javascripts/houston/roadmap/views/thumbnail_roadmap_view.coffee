class Roadmap.ThumbnailRoadmapView
  
  constructor: (options)->
    @milestones = options.milestones
    @parent = options.parent
    @viewport = options.viewport
    @startDate = 3.weeks().ago()
    @endDate = 2.years().after(@startDate)
    @viewerStart = @startDate
    @milestones.bind 'add', @update, @
    @milestones.bind 'change', @update, @
    @milestones.bind 'reset', @update, @
    $(window).resize (e)=>
      @updateWindow() if e.target is window
  
  render: ->
    @$el = $('#roadmap')
    @height = 46
    @graphHeight = @height - 18
    
    svg = @parent.append('svg')
        .attr('height', @height)
        .attr('class', 'roadmap-thumbnail')
      .append('g')
        .attr('transform', "translate(0,0)")
    
    @roadmap = svg.append('g')
      .attr('class', 'roadmap-bands')
    
    drag = d3.behavior.drag()
      .origin((viewport)=> {x: @x(viewport.get('start')), y: 0})
      .on 'drag', (viewport)=>
        x = d3.max [0, d3.event.x]
        x = d3.min [x, @width - @viewer.attr('width')]
        start = @x.invert(x)
        viewport.set(start: start, end: 6.months().after(start))
        @viewer.attr('x', x)
    
    @viewer = svg.selectAll('.roadmap-thumbnail-viewer')
      .data([@viewport])
    
    @viewer.enter()
      .append('rect')
        .attr('class', 'roadmap-thumbnail-viewer')
        .attr('y', 1)
        .attr('height', @height - 2)
        .call(drag)
    
    @xAxis = svg.append('g')
      .attr('class', 'x axis')
      .attr('transform', "translate(0,#{@graphHeight})")
    
    @updateWindow()
  
  updateWindow: ->
    width = $('#roadmap').width() || 960
    return if @width is width
    @width = width
    
    @parent.select('.roadmap-thumbnail').transition(150).attr('width', @width)
    
    @x = d3.time.scale()
      .domain([@startDate, @endDate])
      .range([0, @width])
    timeline = d3.svg.axis()
      .scale(@x)
      .orient('bottom')
      .innerTickSize(4)
    @xAxis.transition(150).call(timeline)
    
    @viewer.transition(150)
      .attr('x', (viewport)=> @x(viewport.get('start')))
      .attr('width', (viewport)=> @x(viewport.get('end')) - @x(viewport.get('start')))
    
    @update()
  
  update: ->
    width = (milestone)->
      return null if !milestone.size or !milestone.units
      weeks = milestone.size
      weeks *= 4.3452380952381 if milestone.units == 'months'
      weeks
    
    certainty = (milestone)->
      return 'certainty-low' if milestone.units.startsWith('mo')
      'certainty-mid'
    
    visibleMilestones = _.select @milestones.sorted().toJSON(), width
    visibleMilestones = _.select visibleMilestones, (m)-> m.startDate
    
    milestoneBands = d3.nest()
      .key (milestone)-> milestone.band
      .entries(visibleMilestones)
    
    startDate = d3.min(visibleMilestones, (milestone)-> milestone.startDate)
    startDate ||= d3.time.format('%Y-%m-%d').parse('2014-08-01')
    endDate = 2.years().after startDate
    
    for milestone in visibleMilestones
      milestone.endDate = width(milestone).weeks().after(milestone.startDate)
    
    bands = @roadmap.selectAll('.roadmap-thumbnail-band')
      .data(milestoneBands, (band)-> band.key)
    
    bands.enter()
      .append('g')
        .attr('class', 'roadmap-thumbnail-band')
        .attr('transform', (d, i)-> "translate(0,#{2 + i * 6})")
    
    bands.exit().remove()
    
    milestones = bands.selectAll('.roadmap-thumbnail-milestone')
      .data(((band)-> band.values), (milestone)-> milestone.id)
    
    # update
    milestones
      .attr('class', (milestone)-> 'roadmap-thumbnail-milestone')
      .transition(150)
        .attr('width', (milestone)=> @x(milestone.endDate) - @x(milestone.startDate))
        .attr('x', (milestone)=> @x(milestone.startDate))
  
    # enter
    milestones.enter().append('rect')
      .attr('rx', 1)
      .attr('ry', 1)
      .attr('height', 5)
      .attr('width', (milestone)=> @x(milestone.endDate) - @x(milestone.startDate))
      .attr('x', (milestone)=> @x(milestone.startDate))
      .attr('class', (milestone)-> 'roadmap-thumbnail-milestone')
    
    # exit
    milestones.exit().remove()
