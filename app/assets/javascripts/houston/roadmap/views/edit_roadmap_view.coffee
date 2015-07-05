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
    if _.keys(milestoneBands).length <= MAX_BANDS
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
      over: (e, ui)->
        return unless view.drag
        band = +$(@).attr('data-band')

        # When we start dragging a multi-lane milestone,
        # note which of its lanes we grabbed.
        unless view.drag.bandOver
          view.drag.bandOffset = band - view.drag.milestone.get('band')

        view.drag.bandOver = band - view.drag.bandOffset

      drop: (e, ui)=>
        return unless @drag

        milestone = @drag.milestone
        startDate = d3.time.monday.round(@x.invert(ui.position.left))
        ui.draggable.css left: @x(startDate)
        endDate = d3.time.saturday.round(milestone.duration().after(startDate))
        milestone.set
          band: @drag.bandOver or milestone.get('band')
          startDate: startDate
          endDate: endDate

        @saveRepositionedMilestones()

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
      
      resize: (e, ui)=>
        return unless @drag

        # If we're _only_ changing the number of lanes
        # this milestone covers, update its duration as
        # its height is changed.
        if @drag.handle is 'ui-resizable-s'
          lanes = @lanesSpanned(ui.size.height)
          if lanes isnt @drag.currentLanes
            @drag.currentLanes = lanes
            originalLanes = @lanesSpanned(ui.originalSize.height)
            ui.size.width = ui.originalSize.width * Math.pow(2, originalLanes - lanes)
            $(ui.element).css(width: ui.size.width)
            @initializeDrag()

        @repositionMilestones ui.size.width - ui.originalSize.width

      stop: (e, ui)=>
        ui.element.resizable 'option', 'grid', false
        ui.element.draggable 'option', 'grid', false
        return unless @drag

        milestone = @drag.milestone
        endDate = d3.time.saturday.round(@x.invert(ui.position.left + ui.size.width))
        ui.element.css width: @x(endDate) - ui.element.position().left
        lanes = @lanesSpanned(ui.size.height)
        milestone.set
          endDate: endDate
          lanes: lanes

        @saveRepositionedMilestones()
        @drag = null

    .draggable
      snap: '.roadmap-band'
      snapMode: 'inner'
      zIndex: 10
      revertDuration: 150
      start: _.bind(@onStartDrag, @)

      drag: (e, ui)=>
        return unless @drag
        @initializeDrag() unless @drag.band is @drag.bandOver

        ui.position.left = Math.max(ui.position.left, @drag.minLeft)

        if e.shiftKey
          if @drag.maxRight
            width = $(e.target).outerWidth()
            ui.position.left = Math.min(ui.position.left, @drag.maxRight - width)
          delta = 0
        else
          delta = ui.position.left - ui.originalPosition.left

        @repositionMilestones(delta)

      stop: (e, ui)=>
        @drag = null
        $(e.target).resizable 'option', 'grid', false
        $(e.target).draggable 'option', 'grid', false

      revert: ($target)-> !$target or !$target.is('.roadmap-band')


  onStartDrag: (e, ui)->
    $milestone = $(e.target)
    return false if $milestone.hasClass('locked')

    handle = $(e.originalEvent.target).attr('class')
    handle = handle.split(' ')[1] if handle

    id = $milestone.attr('data-cid')
    milestone = @milestones.get(id)

    grid = [@weekWidth(), @bandHeight()]
    $milestone.resizable 'option', 'grid', grid
    $milestone.draggable 'option', 'grid', grid

    $('.roadmap-milestone').each ->
      $milestone = $(@)
      $milestone.data('original-left', $milestone.position().left)

    @drag = 
      milestone: milestone
      handle: handle

    @initializeDrag()


  initializeDrag: ->
    milestone = @drag.milestone

    band = @drag.bandOver || milestone.get('band')
    lanes = @drag.currentLanes || milestone.get('lanes')
    bands = (band + i for i in [0...lanes])

    milestonesInBand = @milestones.overlappingBands(bands)
    minStartDate = 2.days().after(milestonesInBand.lastMilestoneBefore(milestone)?.get('endDate'))
    maxEndDate = 2.days().before(milestonesInBand.firstMilestoneAfter(milestone)?.get('startDate'))

    milestonesAfter = @milestones.downstreamOf(milestone.get('endDate'), bands)
    $milestonesAfter = @$el.find(milestonesAfter
      .map (m)-> ".roadmap-milestone[data-cid=#{m.cid}]"
      .join(', '))

    @drag = @drag extends
      band: band
      minLeft: if minStartDate then @x(minStartDate) else 0
      maxRight: maxEndDate && @x(maxEndDate)
      $milestonesAfter: $milestonesAfter


  repositionMilestones: (delta)->
    return unless @drag

    # !todo: check for unmoveable milestones
    @drag.$milestonesAfter.each ->
      $milestone = $(@)
      originalLeft = +$milestone.data('original-left')
      $milestone.css(left: originalLeft + delta)

  saveRepositionedMilestones: ->
    @drag.$milestonesAfter.each (i, el)=>
      $milestone = $(el)
      milestone = @milestones.get $milestone.data('cid')

      unless milestone
        App.debug 'There is no milestone for', $milestone
        return

      if milestone.get('locked')
        App.debug "#{milestone.get('name')} is locked and cannot be repositioned"
        return

      newPosition = $milestone.position().left
      startDate = d3.time.monday.round(@x.invert(newPosition))
      endDate = d3.time.saturday.round(milestone.duration().after(startDate))
      milestone.set
        startDate: startDate
        endDate: endDate




  bandHeight: ->
    38

  weekWidth: ->
    date = d3.time.saturdays(@x.domain()...)[0]
    @x(7.days().after(date)) - @x(date)

  lanesSpanned: (height)->
    # space between lanes is 8; height if lane + space is 38
    (height + 8) / 38

  toJSON: (milestone)->
    json = milestone.toJSON()
    json.cid = milestone.cid # Use `cid` because some milestones may not be saved yet
    json
