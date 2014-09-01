class Roadmap.EditRoadmapView extends Roadmap.RoadmapView
  MAX_BANDS = 4
  
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
    