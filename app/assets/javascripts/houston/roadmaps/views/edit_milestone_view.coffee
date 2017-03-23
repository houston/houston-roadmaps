class Roadmaps.EditMilestoneView extends Roadmaps.ShowMilestoneView
  template: HandlebarsTemplates['houston/roadmaps/milestone/edit']

  events:
    'click .remove-button': 'removeTicket'
    'click .inline-editable-link': 'startInlineEdit'
    'click .btn-cancel': 'cancelInlineEdit'
    'click #save_goal': 'saveGoal'
    'click #save_feedback_query': 'saveFeedbackQuery'
    'click #btn_upgrade': 'upgradeMilestone'

  initialize: (options)->
    @options = options
    @openTickets = @options.openTickets
    super

  render: ->
    super

    @newTicketView = new FindOrCreateTicketView
      ticketTracker: @projectTicketTracker
      tickets: @openTickets
      addTicket: _.bind(@addTicket, @)
      createTicket: _.bind(@createTicket, @)
    @$el.find('#find_or_create_ticket_view').appendView @newTicketView

    $('#tickets').sortable
      handle: '.ticket-handle'
      helper: (e, ui)-> ui.children().each(-> $(@).width $(@).width()); ui
      stop: (e, ui)-> ui.item.children().css('width', '')
      update: (e, ui)->
        $tickets = $('#tickets .ticket')
        ids = _.map $tickets, (el)-> +$(el).attr('data-id')
        $.put "#{window.location.pathname}/ticket_order", {order: ids}
    @



  addTicket: (ticket)->
    $.post("/roadmap/milestones/#{@id}/tickets/#{ticket.id}")
      .success => @_addTicket(ticket)

  createTicket: (summary)->
    $.post("/roadmap/milestones/#{@id}/tickets", {summary: summary})
      .success (ticket)=> @_addTicket(ticket)

  _addTicket: (ticket)->
    unless @tickets.get(ticket.id)
      @tickets.push new Ticket(ticket)
      @rerenderTickets()
      @renderBurndownChart(@tickets.models)
    $(".ticket[data-id=#{ticket.id}]").highlight()



  removeTicket: (e)->
    e.preventDefault()
    e.stopImmediatePropagation()
    $button = $(e.target)
    $button.prop 'disabled', true
    $ticket = $button.closest('.ticket')
    $ticket.addClass('deleting')
    id = +$ticket.attr('data-id')
    $.destroy("/roadmap/milestones/#{@id}/tickets/#{id}")
      .error =>
        $button.prop 'disabled', false
        $ticket.removeClass('deleting')
      .success =>
        @tickets.remove @tickets.get(id)
        $ticket.remove()



  startInlineEdit: (e)->
    $(e.target).closest('.inline-editable')
      .addClass('in-edit')
      .find('input, textarea').focus()

  cancelInlineEdit: (e)->
    e.preventDefault()
    $(e.target).closest('.inline-editable').removeClass('in-edit')

  saveGoal: (e)->
    goal = $('#goal').val()
    $.put("/roadmap/milestones/#{@id}", milestone: {goal: goal})
      .success =>
        @milestone.goal = goal
        @render()
      .error (response)=>
        alertify.error(response.responseText)

  saveFeedbackQuery: (e)->
    feedbackQuery = $('#feedback_query').val()
    $.put("/roadmap/milestones/#{@id}", milestone: {feedback_query: feedbackQuery})
      .success =>
        @milestone.feedbackQuery = feedbackQuery
        @render()
      .error (response)=>
        alertify.error(response.responseText)



  upgradeMilestone: (e)->
    e.preventDefault()
    $.post("/roadmap/milestones/#{@id}/upgrade")
      .success (data)=>
        window.location = data.url
      .error (response)=>
        alertify.error(response.responseText)
