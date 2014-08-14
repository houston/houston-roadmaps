class Roadmap.EditRoadmapView extends Neat.CollectionEditor
  resource: 'milestones'
  viewPath: 'houston/roadmap/milestones'
  sortedBy: null
  pageSize: Infinity
  
  events:
    'click #new_milestone': 'newMilestone'
    'submit #new_milestone_form': 'createMilestone'
    'click #cancel_new_milestone_button': 'resetNewMilestone'
  
  initialize: ->
    @projectId = @options.projectId
    @milestones = @collection = @options.milestones
    @milestones.bind 'change', @updateRoadmap, @
    super
  
  render: ->
    super
    @$el.find('#milestones').sortable
      placeholder: 'ui-state-highlight'
      update: _.bind(@saveSequence, @)
    @drawRoadmap()
    @
  
  saveSequence: ->
    ids = $('.milestone').pluck('data-id')
    $.put "#{window.location.pathname}/order", {order: ids}
  
  newMilestone: ->
    $('#new_milestone').hide()
    $('#new_milestone_form').show()
    $('#new_milestone_name').select()
  
  createMilestone: (e)->
    e.preventDefault()
    $('#new_milestone_form').disable()
    attributes = 
      name: $('#new_milestone_name').val()
      projectId: @projectId
    @milestones.create attributes,
      wait: true
      success: (milestone)=>
        @resetNewMilestone()
      error: (milestone, jqXhr)=>
        $('#new_milestone_form').enable()
        console.log('error', arguments)
        alert(jqXhr.responseText)
  
  resetNewMilestone: ->
    $('#new_milestone').show()
    $('#new_milestone_form').enable().hide()
    $('#new_milestone_name').val('')
  
  
  
  drawRoadmap: ->
    @height = 24
    @margin = {top: 90, right: 80, bottom: 40, left: 50}
    @width = 960
    @height = @width * 0.27
    @graphWidth = @width - @margin.left - @margin.right
    @graphHeight = @height - @margin.top - @margin.bottom
    
    @roadmap = d3.select('#graph').append('svg')
        .attr('width', @width)
        .attr('height', @height)
      .append('g')
        .attr('transform', "translate(0,0)")
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
    
    visibleMilestones = _.select @milestones.sorted().toJSON(), width
    
    for milestone in visibleMilestones
      milestone.startDate = d3.time.format('%Y-%m-%d').parse(milestone.start_date) if milestone.start_date
    startDate = d3.min(visibleMilestones, (milestone)-> milestone.startDate)
    startDate ||= d3.time.format('%Y-%m-%d').parse('2014-08-01')
    
    left = startDate
    space = (width)-> width * 1.25 # 1 week off for every 4
    space = (width)-> width + 0.25
    radius = 4
    for milestone in visibleMilestones
      milestone.width = width(milestone)
      milestone.left = left
      milestone.right = milestone.width.weeks().after(left)
      left = space(milestone.width).weeks().after(left)
    
    x = d3.time.scale()
      .domain([startDate, left])
      .range([@margin.left, @graphWidth])
    
    xAxis = d3.svg.axis()
      .scale(x)
      .orient('bottom')
    
    @xAxis.transition(750).call(xAxis)
    
    milestones = @roadmap.selectAll('.roadmap-milestone')
      .data(visibleMilestones, (milestone)-> milestone.id)
    
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
      .attr('y', @margin.top)
      .attr('class', (milestone)-> "roadmap-milestone #{certainty(milestone)}")
    
    # exit
    milestones.exit().remove()
    
    
    
    clipText = (milestone)->
      name = milestone.name
      maxWidth = x(milestone.right) - x(milestone.left) - 8
      while @getBBox().width > maxWidth
        name = name.substring(0, name.length - 1)
        d3.select(@).select(-> @lastChild).text(name + "...")
    
    milestoneNames = @roadmap.selectAll('.roadmap-milestone-name')
      .data(visibleMilestones, (milestone)-> milestone.id)
    
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
      .attr('y', @margin.top + 17)
      .attr('class', (milestone)-> 'roadmap-milestone-name')
      .text((milestone)-> milestone.name)
      .each(clipText)

    # exit
    milestoneNames.exit().remove()

