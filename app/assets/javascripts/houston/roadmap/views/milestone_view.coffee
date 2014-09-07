class window.MilestoneView extends Neat.ModelEditor
  
  render: ->
    super
    @$el.attr 'data-id', @model.get('id')
    @
