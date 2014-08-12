class window.MilestoneView extends Neat.ModelEditor
  
  render: ->
    super
    @$el.attr 'data-id', @model.get('id')
    @
  
  attributesFromForm: ($form)->
    attributes = super($form)
    [_, size, units] = attributes.size.match(/(\d+) ?(weeks?|wks?|months?|mos?)/) ? []
    attributes.units = switch units?[0]
      when "w" then "weeks"
      when "m" then "months"
      else null
    attributes.size = size && +size
    attributes
  
  okToSave: (attributes)->
    return true if !attributes.units?
    return false if !_.contains ["weeks", "months"], attributes.units
    super
