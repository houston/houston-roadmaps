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
      @$newMilestone.css(width: newMilestoneWidth)
  
  
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
      drop: (event, ui)->
        band = $(@).attr('data-band')
        id = ui.draggable.attr('data-id')
        milestone = view.milestones.get(id)
        return unless milestone
        
        startDate = d3.time.monday.round(view.x.invert(ui.position.left))
        ui.draggable.css left: view.x(startDate)
        
        offset = Math.floor((startDate - milestone.get('startDate')) / Duration.DAY)
        endDate = offset.days().after milestone.get('endDate')
        milestone.save
          band: band
          startDate: startDate
          endDate: endDate
        , wait: true
    .on 'mousedown', (e)->
      return unless view.supportsCreate
      return if e.target isnt @
      view.newMilestoneX = e.screenX
      view.$el.addClass('drag-create')
      view.$newMilestone = $('<div class="roadmap-milestone-placeholder">&nbsp;</div>')
        .css(left: e.offsetX)
        .appendTo(@)
  
  initializeMilestone: (milestone)->
    view = @
    $(milestone).resizable
      handles: 'e'
      animate: false
      stop: (event, ui)->
        id = ui.element.attr('data-id')
        milestone = view.milestones.get(id)
        return unless milestone
        endDate = d3.time.saturday.round(view.x.invert(ui.position.left + ui.size.width))
        ui.element.css width: view.x(endDate) - ui.element.position().left
        milestone.save
          endDate: endDate
        , wait: true
    .draggable
      snap: '.roadmap-band'
      snapMode: 'inner'
      zIndex: 10
      revertDuration: 150
      revert: ($target)-> !$target or !$target.is('.roadmap-band')

