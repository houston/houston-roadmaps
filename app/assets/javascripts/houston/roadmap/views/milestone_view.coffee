class window.MilestoneView extends Neat.ModelEditor
  tagName: 'tr'
  
  render: ->
    super
    @$el.attr 'data-id', @model.get('id')
    @$el.toggleClass 'locked', @model.get('locked')
    @$el.toggleClass 'completed', @model.get('completed')
    @
