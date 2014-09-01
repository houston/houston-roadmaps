class Roadmap.EditRoadmapView extends Roadmap.RoadmapView
  MAX_BANDS = 4
  $newMilestone: null
  newMilestoneX: null
  supportsCreate: false
  
  
  constructor: (milestones, options={})->
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
        weeks = Math.round (endDate - startDate) / Duration.WEEK
        attributes = 
          band: band
          startDate: startDate
          size: weeks || 1
          units: 'weeks'
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
    projectColor = {}
    milestoneBands = {}
    bandsByProject = {}
    for milestone in @milestones.sorted().toJSON() when @widthOfMilestone(milestone)
      milestone.startDate = @today unless milestone.startDate
      milestone.duration = @widthOfMilestone(milestone)
      milestone.endDate = milestone.duration.weeks().after(milestone.startDate)
      
      projectColor[milestone.projectId] = milestone.projectColor
      key = "#{milestone.projectId}-#{milestone.band}"
      (milestoneBands[key] ||=
        key: key
        projectId: milestone.projectId
        color: milestone.projectColor
        number: milestone.band
        milestones: []).milestones.push(milestone)
      (bandsByProject[milestone.projectId] ||= d3.set()).add(milestone.band)
    
    milestoneBands = _.values(milestoneBands)
    
    for projectId, bands of bandsByProject when bands.values().length < MAX_BANDS
      newBand = +d3.max(bands.values()) + 1
      key = "#{projectId}-#{newBand}"
      milestoneBands.push
        key: key
        projectId: projectId
        color: projectColor[projectId]
        number: newBand
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
        date = view.x.invert(ui.position.left)
        attributes = 
          band: band
          startDate: d3.time.monday.round(date)
        milestone.save(attributes, wait: true)
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
      stop: (event, ui)->
        id = ui.element.attr('data-id')
        milestone = view.milestones.get(id)
        return unless milestone
        endDate = view.x.invert(ui.position.left + ui.size.width)
        weeks = Math.round (endDate - milestone.get('startDate')) / Duration.WEEK
        milestone.save size: weeks
    .draggable
      snap: '.roadmap-band'
      snapMode: 'inner'
      zIndex: 10
      revertDuration: 150
      revert: ($target)-> !$target or !$target.is('.roadmap-band')

