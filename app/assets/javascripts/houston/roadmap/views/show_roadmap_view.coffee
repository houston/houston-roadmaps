class Roadmap.ShowRoadmapView extends Backbone.View
  
  initialize: ->
    @projects = @options.projects
    for project in @projects
      project.milestones = _.select project.milestones, (milestone)-> milestone.size && milestone.units
    @projects = _.select @projects, (project)-> project.milestones.length > 0
  
  render: ->
    @drawRoadmap()
    @
  
  
  
  drawRoadmap: ->
    @height = 24
    @margin = {top: 60, right: 80, bottom: 40, left: 50}
    @width = 960
    @height = @width * 0.27
    @graphWidth = @width - @margin.left - @margin.right
    @graphHeight = @height - @margin.top - @margin.bottom
    
    @roadmap = d3.select('#graph').append('svg')
        .attr('width', @width)
        .attr('height', @height)
      .append('g')
        .attr('transform', 'translate(0,0)')
    @xAxis = @roadmap.append('g')
      .attr('class', 'x axis')
      .attr('transform', "translate(0,#{@graphHeight})")
    @updateRoadmap()
  
  updateRoadmap: ->
    width = (milestone)->
      return null if !milestone.size or !milestone.units
      weeks = milestone.size
      weeks *= 4.3452380952381 if milestone.units == 'months'
      weeks
    
    certainty = (milestone)->
      return 'certainty-low' if milestone.units.startsWith('mo')
      'certainty-mid'
    
    space = (width)-> width * 1.25 # 1 week off for every 4
    space = (width)-> width + 0.25
    radius = 4
    for project in @projects
      for milestone in project.milestones
        milestone.startDate = d3.time.format('%Y-%m-%d').parse(milestone.start_date) if milestone.start_date
      startDate = d3.min(project.milestones, (milestone)-> milestone.startDate)
      startDate ||= d3.time.format('%Y-%m-%d').parse('2014-08-01')
      
      left = startDate
      for milestone in project.milestones
        milestone.width = width(milestone)
        milestone.left = left
        milestone.right = milestone.width.weeks().after(left)
        left = space(milestone.width).weeks().after(left)
    
    x = d3.time.scale()
      .domain([startDate, left])
      .range([@margin.left, @graphWidth])
    
    y = d3.scale.ordinal()
      .domain(_.map @projects, (project)-> project.id)
      .rangeBands([@margin.top, @graphHeight])
    
    xAxis = d3.svg.axis()
      .scale(x)
      .orient('bottom')
    
    @xAxis.transition(750).call(xAxis)
    
    bands = @roadmap.selectAll('.roadmap-band')
      .data(@projects, (project)-> project.id)
    
    bands.enter().append('g')
      .attr('class', (project)-> "roadmap-band #{project.color}")
      .attr('transform', (project)-> "translate(0,#{y(project.id)})")
    
    milestones = bands.selectAll('.roadmap-milestone')
      .data(((project)-> project.milestones), ((milestone)-> milestone.id))
    
    # update
    milestones
      .attr('class', (milestone)-> "roadmap-milestone #{certainty(milestone)}")
      .transition(750)
        .attr('width', (milestone)-> x(milestone.right) - x(milestone.left))
        .attr('x', (milestone)-> x(milestone.left))
  
    # enter
    milestones.enter().append('rect')
      .attr('rx', radius)
      .attr('ry', radius)
      .attr('height', 24)
      .attr('width', (milestone)-> x(milestone.right) - x(milestone.left))
      .attr('x', (milestone)-> x(milestone.left))
      .attr('y', 0)
      .attr('class', (milestone)-> "roadmap-milestone #{certainty(milestone)}")
    
    # exit
    milestones.exit().remove()
    
    
    
    clipText = (milestone)->
      name = milestone.name
      maxWidth = x(milestone.right) - x(milestone.left) - 8
      while @getBBox().width > maxWidth
        name = name.substring(0, name.length - 1)
        d3.select(@).select(-> @lastChild).text(name + "...")
    
    milestoneNames = bands.selectAll('.roadmap-milestone-name')
      .data(((project)-> project.milestones), ((milestone)-> milestone.id))
    
    # update
    milestoneNames
      .text((milestone)-> milestone.name)
      .each(clipText)
      .transition(750)
        .attr('x', (milestone)-> (x(milestone.left) + x(milestone.right)) / 2)

    # enter
    milestoneNames.enter().append('text')
      .attr('text-anchor', 'middle')
      .attr('x', (milestone)-> (x(milestone.left) + x(milestone.right)) / 2)
      .attr('y', 17)
      .attr('class', (milestone)-> 'roadmap-milestone-name')
      .text((milestone)-> milestone.name)
      .each(clipText)

    # exit
    milestoneNames.exit().remove()


