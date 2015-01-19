Handlebars.registerPartial 'milestoneTicket', (task)->
  HandlebarsTemplates['houston/roadmap/milestone/ticket'](task)

Handlebars.registerHelper 'durationOfMilestone', (milestone)->
  return "" unless milestone.endDate and milestone.startDate
  duration = milestone.endDate - milestone.startDate
  weeks = Math.round(duration / Duration.WEEK)
  "#{weeks} weeks"

Handlebars.registerHelper 'milestonePercentComplete', (milestone)->
  return "" if !milestone.percentComplete?
  App.formatPercent milestone.percentComplete

Handlebars.registerHelper 'linkToFeedbackQuery', (projectSlug, feedbackQuery)->
  q = encodeURIComponent(feedbackQuery)
  path = "/feedback/by_project/#{projectSlug}?q=#{q}"
  "<a href=\"#{path}\">See comments</a>"
