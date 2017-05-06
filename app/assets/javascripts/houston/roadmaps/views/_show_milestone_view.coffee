class Roadmaps.ShowMilestoneView extends @TicketsView
  supportsSorting: false
  template: HandlebarsTemplates['houston/roadmaps/milestone/show']

  initialize: (options)->
    @options = options
    @milestone = @options.milestone
    @id = @milestone.id
    @projectTicketTracker = @options.projectTicketTracker
    @usesFeedback = @options.usesFeedback
    super

    @$el.on 'click', '#show_completed_tickets', _.bind(@toggleShowCompleted, @)

  render: ->
    tickets = for ticket in @tickets.models
      json = ticket.toJSON()
      json.estimatedEffortCompleted = ticket.estimatedEffortCompleted()
      json.estimatedEffort = ticket.estimatedEffort()
      json

    html = @template
      projectSlug: @project
      milestone: @milestone
      usesFeedback: @usesFeedback
      tickets: tickets
    @$el.html html

    complete = _.select(tickets, (ticket)-> !!ticket.closedAt).length / tickets.length
    if _.isNaN(complete)
      $('.milestone-progress').hide()
    else
      $('#milestone_progress').html(App.formatPercent complete)
      $('.milestone-progress').show()

    @renderBurndownChart(@tickets.models)
    @



  rerenderTickets: ->
    template = HandlebarsTemplates['houston/roadmaps/milestone/ticket']
    $tickets = @$el.find('#tickets')
    return @render() if $tickets.length is 0
    $tickets.empty()
    for ticket in @tickets.models
      json = ticket.toJSON()
      json.estimatedEffortCompleted = ticket.estimatedEffortCompleted()
      json.estimatedEffort = ticket.estimatedEffort()
      $tickets.append template(json)



  renderBurndownChart: (tickets)->
    tasks = for ticket in tickets
      openedAt: App.parseDate(ticket.get('openedAt'))
      closedAt: App.parseDate(ticket.get('closedAt'))
      deletedAt: App.parseDate(ticket.get('deletedAt'))
      effort: +ticket.estimatedEffort()

    chart = new Houston.BurndownChart()
      .snapTo((date)=> @getEndOfSprint(date))
      .prevTick((date)=> @prevSprint(date))
      .nextTick((date)=> @nextSprint(date))
      .dateFormat(d3.time.format('%b %e'))
      .data(tasks, regression: true)
      .render()

    insertLinebreaks = (d)->
      el = d3.select(this)
      words = el.text().split(/\s+/)
      el.text('')

      el.append('tspan').text(words[0]).attr('class', 'month')
      el.append('tspan').text(words[1]).attr('x', 0).attr('dy', '11').attr('class', 'day')

    svg = d3.select('#graph').select('svg')
    svg.selectAll('.x.axis text').each(insertLinebreaks)

  prevSprint: (date)->
    1.week().before(date)

  nextSprint: (date)->
    1.week().after(date)

  getEndOfSprint: (date)->
    @getNextFriday(date)

  getNextFriday: (date)->
    wday = date.getDay() # 0-6 (0=Sunday)
    daysUntilFriday = 5 - wday # 5=Friday
    daysUntilFriday += 7 if daysUntilFriday < 0
    daysUntilFriday.days().after(date)



  toggleShowCompleted: (e)->
    $button = $(e.target)
    if $button.hasClass('active')
      $button.removeClass('btn-success')
      @$el.addClass('hide-completed')
    else
      $button.addClass('btn-success')
      @$el.removeClass('hide-completed')
