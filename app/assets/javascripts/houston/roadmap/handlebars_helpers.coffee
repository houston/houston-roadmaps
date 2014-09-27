Handlebars.registerPartial 'milestoneTicket', (task)->
  HandlebarsTemplates['houston/roadmap/milestone/ticket'](task)

Handlebars.registerHelper 'durationOfMilestone', (milestone)->
  return "" unless milestone.endDate and milestone.startDate
  duration = milestone.endDate - milestone.startDate
  weeks = Math.round(duration / Duration.WEEK)
  "#{weeks} weeks"

Handlebars.registerHelper 'milestonePercentComplete', (milestone)->
  return "" if milestone.tickets == 0
  App.formatPercent milestone.ticketsCompleted / milestone.tickets
