Handlebars.registerPartial 'milestoneTicket', (task)->
  HandlebarsTemplates['houston/roadmap/milestone/ticket'](task)

Handlebars.registerHelper 'durationOfMilestone', (milestone)->
  duration = milestone.endDate - milestone.startDate
  weeks = Math.round(duration / Duration.WEEK)
  "#{weeks} weeks"
