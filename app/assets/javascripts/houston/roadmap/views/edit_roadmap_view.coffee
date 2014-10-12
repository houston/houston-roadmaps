class Roadmap.EditRoadmapView extends Roadmap.RoadmapView
  MAX_BANDS = 4
  $newMilestone: null
  newMilestoneX: null
  supportsCreate: false
  
  
  constructor: (milestones, options={})->
    @project = options.project
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
      newMilestoneWidth = e.screenX - @newMilestoneX
      if newMilestoneWidth > 10
        band = +@$newMilestone.closest('.roadmap-band').attr('data-band')
        startDate = @x.invert(@$newMilestone.position().left)
        endDate = @x.invert(@$newMilestone.position().left + @$newMilestone.width())
        attributes = 
          band: band
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
      
      startDate = @x.invert(@$newMilestone.position().left)
      endDate = d3.time.saturday.round(@x.invert(@$newMilestone.position().left + newMilestoneWidth))
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
        
        milestone.set
          band: band
          startDate: startDate
          endDate: milestone.duration().after startDate
        
        return unless view.drag
        return unless view.drag.band is view.drag.bandOver
        return unless view.drag.maxLeft
        return unless ui.position.left > view.drag.maxLeft
        
        delta = ui.position.left - view.drag.offsetLeft + view.drag.originalLeft - view.drag.maxLeft
        
        for i in [0...view.drag.milestonesAfter.length]
          milestone = view.drag.milestonesAfter[i]
          originalPosition = view.drag.milestonesAfterPositions[i]
          newPosition = originalPosition + delta
          startDate = d3.time.monday.round(view.x.invert(newPosition))
          milestone.set
            startDate: startDate
            endDate: milestone.duration().after startDate
    
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
      handles: 'e'
      animate: false
      start: _.bind(@onStartDrag, @)
      
      resize: (event, ui)->
        return unless view.drag
        
        delta = ui.size.width - ui.originalSize.width
        if view.drag.maxLeft
          delta += view.drag.originalLeft - view.drag.maxLeft
          delta = 0 if delta < 0
        
        view.drag.$milestonesAfter.each (i)->
          $(@).css(left: view.drag.milestonesAfterPositions[i] + delta)
      
      stop: (event, ui)->
        id = ui.element.attr('data-cid')
        milestone = view.milestones.get(id)
        return unless milestone
        endDate = d3.time.saturday.round(view.x.invert(ui.position.left + ui.size.width))
        ui.element.css width: view.x(endDate) - ui.element.position().left
        milestone.set
          endDate: endDate
        
        return unless view.drag
        return unless view.drag.maxLeft
        
        delta = ui.size.width - ui.originalSize.width
        if view.drag.maxLeft
          delta += view.drag.originalLeft - view.drag.maxLeft
          delta = 0 if delta < 0
        
        return unless delta > 0
        
        for i in [0...view.drag.milestonesAfter.length]
          milestone = view.drag.milestonesAfter[i]
          originalPosition = view.drag.milestonesAfterPositions[i]
          newPosition = originalPosition + delta
          startDate = d3.time.monday.round(view.x.invert(newPosition))
          milestone.set
            startDate: startDate
            endDate: milestone.duration().after startDate
    
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
        view.drag.$milestonesAfter.each (i)->
          $(@).css(left: view.drag.milestonesAfterPositions[i] + delta)
      
      stop: -> view.drag = null
      revert: ($target)-> !$target or !$target.is('.roadmap-band')


  onStartDrag: (e, ui)->
    $milestone = $(e.target)
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
    
    for milestone in milestonesInBand
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
