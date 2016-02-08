class window.GoalView extends Neat.ModelEditor
  tagName: 'tr'

  render: ->
    super
    @$el.attr 'data-cid', @model.cid
    @$el.toggleClass 'new', !@model.get('id')
    @

  cancelEdit: (e)->
    return super if @model.id

    # Canceling editing a new goal cancels adding a goal
    @model.collection.remove @model

  onSaveError: (goal, response) ->
    errors = Errors.fromResponse(response)
    errors.renderToAlert()
