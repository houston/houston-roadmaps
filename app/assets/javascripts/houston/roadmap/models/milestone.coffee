class Roadmap.Milestone extends Backbone.Model
  urlRoot: '/roadmap/milestones'
  
  initialize: ->
    super
    _.bindAll(@, 'clearChangesSinceSave', 'revert')
    @clearChangesSinceSave()
  
  save: (attrs, options)->
    success = options?.success
    options.success = (response)=>
      @trigger('save:success', @)
      success(@, response) if success
      @clearChangesSinceSave()
    @trigger('save', @)
    super
  
  duration: ->
    Math.floor((@get('endDate') - @get('startDate')) / Duration.DAY).days()
  
  clearChangesSinceSave: ->
    @_originalAttributes = _.clone @attributes
  
  revert: ->
    @set(@_originalAttributes) if @_originalAttributes
  
  changesSinceSave: ->
    changes = {}
    for attribute, value of @attributes
      originalValue = @_originalAttributes[attribute]
      changes[attribute] = [originalValue, value] unless _.isEqual(originalValue, value)
    changes
  
  
  
  parse: (milestone)->
    milestone.startDate = App.serverDateFormat.parse(milestone.startDate) if milestone.startDate
    milestone.endDate = App.serverDateFormat.parse(milestone.endDate) if milestone.endDate
    milestone
  
  toJSON: (options)->
    json = super(options)
    if 'emulateHTTP' of (options || {})
      json.start_date = App.serverDateFormat(json.startDate) if json.startDate
      delete json.startDate
      json.end_date = App.serverDateFormat(json.endDate) if json.endDate
      delete json.endDate
    json

class Roadmap.Milestones extends Backbone.Collection
  model: Roadmap.Milestone
  
  start: -> _.min @pluck('startDate')
  end: -> _.max @pluck('endDate')
  
  revert: ->
    @each (milestone)-> milestone.revert()
  
  clearChangesSinceSave: ->
    @each (milestone)-> milestone.clearChangesSinceSave()
  
  changes: ->
    for milestone in @models when _.keys(changes = milestone.changesSinceSave()).length > 0
      change = id: milestone.id
      for attribute, [originalView, newValue] of changes
        [attribute, newValue] = ['start_date', App.serverDateFormat(newValue)] if attribute is 'startDate'
        [attribute, newValue] = ['end_date', App.serverDateFormat(newValue)] if attribute is 'endDate'
        change[attribute] = newValue 
      change
