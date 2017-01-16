class Houston::Roadmaps::TicketPresenter < Houston::Tickets::TicketPresenter
  include MarkdownHelper

  def ticket_to_json(ticket)
    reporter = ticket.reporter
    super.merge(
      tasks: ticket.tasks.map { |task| task.ticket = ticket; {
        id: task.id,
        description: task.description,
        completedAt: task.completed_at,
        number: task.number,
        letter: task.letter,
        effort: task.effort } },
      reporter: reporter && {
        email: reporter.email,
        name: reporter.name },
      closedAt: ticket.closed_at)
  end

end
