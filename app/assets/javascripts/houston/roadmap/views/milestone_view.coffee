class window.MilestoneView extends Neat.ModelEditor
  tagName: 'tr'
  
  render: ->
    super
    @$el.attr 'data-cid', @model.cid
    @$el.toggleClass 'new', !@model.get('id')
    @$el.toggleClass 'locked', @model.get('locked')
    @$el.toggleClass 'completed', @model.get('completed')
    @
