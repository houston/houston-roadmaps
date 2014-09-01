class Roadmap.Milestone extends Backbone.Model
  urlRoot: '/roadmap/milestones'
  
  parse: (milestone)->
    milestone.startDate = App.serverDateFormat.parse(milestone.startDate) if milestone.startDate
    milestone
  
  toJSON: (options)->
    json = super(options)
    if options?.success
      json.start_date = App.serverDateFormat(json.startDate) if json.startDate
      delete json.startDate
    json

class Roadmap.Milestones extends Backbone.Collection
  model: Roadmap.Milestone
  
  sorted: -> new Roadmap.Milestones(@sortBy (milestone)-> milestone.get('position'))
