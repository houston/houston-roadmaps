class Roadmap.Milestone extends Backbone.Model
  urlRoot: '/roadmap/milestones'
  
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
