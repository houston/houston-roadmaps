class Roadmap.EditRoadmapView extends Roadmap.RoadmapView
  MAX_BANDS = 4
  $newMilestone: null
  newMilestoneX: null
  supportsCreate: false
  
  
  constructor: (milestones, options={})->
    @project = options.project
    @gapWeeks = options.gapWeeks ? 0
    super(milestones, options)
    $(document.body).on 'keyup', (e)=>
      return unless @$newMilestone and @supportsCreate
      @cancelCreate() if e.keyCode is 27
  
  
  createMilestone: (callback)->
    @supportsCreate = !!callback
    @_createMilestoneCallback = callback
    @
  
  
  render: ->
    super
    @$el.on 'mouseleave', => @cancelCreate()
    
    @$el.on 'mouseup', (e)=>
      return unless @$newMilestone and @supportsCreate
      newMilestoneWidth = @$newMilestone.outerWidth()
      if newMilestoneWidth > 10
        band = +@$newMilestone.closest('.roadmap-band').attr('data-band')
        left = @$newMilestone.position().left
        startDate = @x.invert(left)
        endDate = @x.invert(left + newMilestoneWidth)
        attributes = 
          band: band
          lanes: 1
          startDate: d3.time.monday.round(startDate)
          endDate: d3.time.saturday.round(endDate)
        @$newMilestone.addClass('creating').text('Saving...')
        @$el.removeClass('drag-create')
        [$newMilestone, @$newMilestone] = [@$newMilestone, null]
        @_createMilestoneCallback attributes, -> $newMilestone.remove()
      else
        @cancelCreate()
    
    @$el.on 'mousemove', (e)=>
      return unless @$newMilestone and @supportsCreate
      newMilestoneWidth = e.screenX - @newMilestoneX
      newMilestoneWidth = 0 if newMilestoneWidth < 0
      
      left = @$newMilestone.position().left
      startDate = @x.invert(left)
      endDate = d3.time.saturday.round(@x.invert(@$newMilestone.position().left + newMilestoneWidth))
      newMilestoneWidth = @x(endDate) - left
      milliseconds = endDate.getTime() - startDate.getTime() + 2 * Duration.DAY
      weeks = Math.floor(milliseconds / Duration.WEEK)
      
      @$newMilestone.css(width: newMilestoneWidth)
      if weeks < 2
        @$newMilestone.html("&nbsp;")
      else
        @$newMilestone.html("<span>#{weeks}&nbsp;weeks</span>")
  
  
  cancelCreate: ->
    return unless @$newMilestone and @supportsCreate
    @$el.removeClass('drag-create')
    @$newMilestone.remove()
    @$newMilestone = null
  
  
  groupMilestonesIntoBands: ->
    milestoneBands = super
    
    nextBand = +d3.max(milestoneBands, (band)-> band.number) + 1
    nextBand = 1 if _.isNaN(nextBand)
    if nextBand <= MAX_BANDS
      milestoneBands.push
        key: "#{@project.id}-#{nextBand}"
        projectId: @project.id
        color: @project.color
        number: nextBand
        milestones: []
    
    milestoneBands
  
  
  initializeBand: (band)->
    view = @
    
    $(band).droppable
      hoverClass: 'sort-active'
      tolerance: 'pointer'
      over: (event, ui)->
        return unless view.drag
        view.drag.bandOver = +$(@).attr('data-band')
        
      drop: (event, ui)->
        band = +$(@).attr('data-band')
        id = ui.draggable.attr('data-cid')
        milestone = view.milestones.get(id)
        return unless milestone
        
        startDate = d3.time.monday.round(view.x.invert(ui.position.left))
        ui.draggable.css left: view.x(startDate)
        endDate = d3.time.saturday.round(milestone.duration().after(startDate))
        
        milestone.set
          band: band
          startDate: startDate
          endDate: endDate
        
        return unless view.drag
        return unless view.drag.band is view.drag.bandOver
        
        for i in [0...view.drag.milestonesAfter.length]
          milestone = view.drag.milestonesAfter[i]
          unless milestone.get('locked')
            $milestone = $ view.drag.$milestonesAfter[i]
            newPosition = $milestone.position().left
            startDate = d3.time.monday.round(view.x.invert(newPosition))
            endDate = d3.time.saturday.round(milestone.duration().after(startDate))
            milestone.set
              startDate: startDate
              endDate: endDate
    
    .on 'mousedown', (e)->
      return unless view.supportsCreate
      return if e.target isnt @
      view.newMilestoneX = e.screenX
      view.$el.addClass('drag-create')
      
      startDate = d3.time.monday.round(view.x.invert(e.offsetX))
      
      view.$newMilestone = $('<div class="roadmap-milestone-placeholder">&nbsp;</div>')
        .css(left: view.x(startDate))
        .appendTo(@)
  
  initializeMilestone: (milestone)->
    view = @
    $(milestone).resizable
      handles: 'e, s, se'
      animate: false
      start: _.bind(@onStartDrag, @)
      
      resize: (event, ui)->
        return unless view.drag
        
        # If we're _only_ changing the number of lanes
        # this milestone covers, update its duration as
        # its height is changed.
        if view.drag.handle is 'ui-resizable-s'
          originalLanes = (ui.originalSize.height + 8) / 38 # space between lanes is 8; height if lane + space is 38
          lanes = (ui.size.height + 8) / 38 # space between lanes is 8; height if lane + space is 38
          lanesDelta = lanes - originalLanes
          ui.size.width = ui.originalSize.width * Math.pow(2, -lanesDelta)
          $(@).css(width: ui.size.width)
        
        delta = ui.size.width - ui.originalSize.width
        if view.drag.maxLeft
          delta += view.drag.originalLeft - view.drag.maxLeft
          delta = 0 if delta < 0
        
        lastRight = ui.position.left + ui.size.width
        view.drag.$milestonesAfter.each (i)->
          left = view.drag.milestonesAfterPositions[i]
          gap = if i is 0 then 0 else view.drag.minGap
          left = Math.max(left + delta, lastRight + gap) if delta > 0 and !$(@).hasClass('locked')
          $(@).css(left: left)
          lastRight = left + $(@).outerWidth()
      
      stop: (event, ui)->
        ui.element.resizable 'option', 'grid', false
        ui.element.draggable 'option', 'grid', false
        
        id = ui.element.attr('data-cid')
        milestone = view.milestones.get(id)
        return unless milestone
        endDate = d3.time.saturday.round(view.x.invert(ui.position.left + ui.size.width))
        ui.element.css width: view.x(endDate) - ui.element.position().left
        lanes = (ui.size.height + 8) / 38 # space between lanes is 8; height if lane + space is 38
        milestone.set
          endDate: endDate
          lanes: lanes
        
        return unless view.drag
        
        for i in [0...view.drag.milestonesAfter.length]
          milestone = view.drag.milestonesAfter[i]
          unless milestone.get('locked')
            $milestone = $ view.drag.$milestonesAfter[i]
            newPosition = $milestone.position().left
            startDate = d3.time.monday.round(view.x.invert(newPosition))
            endDate = d3.time.saturday.round(milestone.duration().after(startDate))
            milestone.set
              startDate: startDate
              endDate: endDate
    
    .draggable
      snap: '.roadmap-band'
      snapMode: 'inner'
      zIndex: 10
      revertDuration: 150
      start: _.bind(@onStartDrag, @)
      
      drag: (e, ui)->
        return unless view.drag
        if view.drag.band is view.drag.bandOver
          ui.position.left = Math.max(ui.position.left, view.drag.minLeft)
          delta = ui.position.left - view.drag.offsetLeft
          if view.drag.maxLeft
            delta += view.drag.originalLeft - view.drag.maxLeft
            delta = 0 if delta < 0
        else
          delta = 0
        
        lastRight = ui.position.left + ui.helper.outerWidth()
        view.drag.$milestonesAfter.each (i)->
          left = view.drag.milestonesAfterPositions[i]
          gap = if i is 0 then 0 else view.drag.minGap
          left = Math.max(left + delta, lastRight + gap) if delta > 0 and !$(@).hasClass('locked')
          $(@).css(left: left)
          lastRight = left + $(@).outerWidth()
      
      stop: (e, ui)->
        view.drag = null
        $(e.target).resizable 'option', 'grid', false
        $(e.target).draggable 'option', 'grid', false
        
      revert: ($target)-> !$target or !$target.is('.roadmap-band')


  onStartDrag: (e, ui)->
    handle = $(e.originalEvent.target).attr('class')
    handle = handle.split(' ')[1] if handle
    $milestone = $(e.target)
    return false if $milestone.hasClass('locked')
    band = +$milestone.closest('.roadmap-band').attr('data-band')
    id = $milestone.attr('data-cid')
    milestone = @milestones.get(id)
    startDate = milestone.get 'startDate'
    endDate = milestone.get 'endDate'
    duration = Math.floor((endDate - startDate) / Duration.DAY).days()
    milestonesInBand = @milestones.where(band: band)
    minStartDate = null
    maxStartDate = null
    milestonesAfter = []
    
    grid = [@weekWidth(), @bandHeight()]
    $milestone.resizable 'option', 'grid', grid
    $milestone.draggable 'option', 'grid', grid
    
    for milestone in milestonesInBand
      if milestone.get('startDate') && milestone.get('endDate')
        if milestone.get('endDate') < startDate
          minStartDate = 2.days().after(milestone.get('endDate'))
        else if milestone.get('startDate') > endDate
          maxStartDate ||= duration.before(2.days().before(milestone.get('startDate')))
          milestonesAfter.push milestone
    
    selector = _.map milestonesAfter, (m)-> ".roadmap-milestone[data-cid=#{m.cid}]"
    $milestonesAfter = @$el.find(selector.join(', '))
    milestonesAfterPositions = $milestonesAfter.map -> $(@).position().left
    
    @drag = 
      milestone: milestone
      band: band
      minLeft: if minStartDate then @x(minStartDate) else 0
      maxLeft: if maxStartDate then @x(maxStartDate) else 0
      milestonesAfter: milestonesAfter
      $milestonesAfter: $milestonesAfter
      milestonesAfterPositions: milestonesAfterPositions
      offsetLeft: ui.position.left
      originalLeft: $milestone.position().left
      handle: handle
      minGap: @minGap()



  bandHeight: ->
    38

  weekWidth: ->
    date = d3.time.saturdays(@x.domain()...)[0]
    @x(7.days().after(date)) - @x(date)

  minGap: ->
    date = d3.time.saturdays(@x.domain()...)[0]
    weekend = @x(2.days().after(date)) - @x(date)
    week = @x(7.days().after(date)) - @x(date)
    weekend + (week * @gapWeeks)

  toJSON: (milestone)->
    json = milestone.toJSON()
    json.cid = milestone.cid # Use `cid` because some milestones may not be saved yet
    json
