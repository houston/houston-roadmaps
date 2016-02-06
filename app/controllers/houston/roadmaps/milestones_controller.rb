module Houston
  module Roadmaps
    class MilestonesController < ApplicationController
      attr_reader :milestone

      layout "houston/roadmaps/application"

      before_filter :find_milestone, only: [:show, :update, :close, :add_ticket, :create_ticket, :remove_ticket, :update_order]


      def show
        authorize! :read, milestone
        @project = milestone.project
        @title = "#{milestone.name} • #{@project.name}"
        @tickets = milestone.tickets.includes(:project, :tasks, :reporter)
        @open_tickets = @project.tickets.open.includes(:tasks, :reporter)
      end


      def create
        project = Project.find(params[:projectId])
        authorize! :create, project.milestones.build
        milestone = project.create_milestone!(milestone_attributes)
        if milestone.persisted?
          render json: Houston::Roadmaps::MilestonePresenter.new(milestone), status: :created
        else
          render json: milestone.errors, status: :unprocessable_entity
        end
      end


      def update
        authorize! :update, milestone
        milestone.updated_by = current_user
        if milestone.update_attributes(milestone_attributes)
          render json: Houston::Roadmaps::MilestonePresenter.new(milestone)
        else
          render json: milestone.errors, status: :unprocessable_entity
        end
      end


      def close
        authorize! :update, milestone
        milestone.close!
        render json: {}
      end


      def add_ticket
        authorize! :update_tickets, milestone
        ticket = Ticket.find params[:ticket_id]
        ticket.update_attribute :milestone_id, milestone.id
        head :ok
      end


      def create_ticket
        authorize! :update_tickets, milestone
        authorize! :create, milestone.tickets.build

        ticket = project.create_ticket!(
          milestone_id: milestone.id,
          type: "Feature",
          summary: params[:summary],
          reporter: current_user)

        if ticket.persisted?
          render json: TicketPresenter.new(ticket), status: :created, location: ticket.ticket_tracker_ticket_url
        else
          render json: ticket.errors, status: :unprocessable_entity
        end
      end


      def remove_ticket
        authorize! :update_tickets, milestone
        ticket = Ticket.find params[:ticket_id]
        ticket.update_attribute :milestone_id, nil
        head :ok
      end


      def update_order
        authorize! :update_tickets, milestone

        ids = Array.wrap(params[:order]).map(&:to_i).reject(&:zero?)

        ::Ticket.transaction do
          milestone.tickets.where(::Ticket.arel_table[:id].not_in(ids))
            .update_all("extended_attributes = extended_attributes || 'milestoneSequence=>NULL'::hstore")

          ids.each_with_index do |id, i|
            ::Ticket.unscoped.where(id: id).update_all("extended_attributes = extended_attributes || 'milestoneSequence=>#{i+1}'::hstore")
          end
        end

        head :ok
      end


    private

      def find_milestone
        @milestone = Milestone.unscoped.find(params[:id])
      end

      def project
        milestone.project
      end

      def milestone_attributes
        params.fetch(:milestone).pick(:name, :band, :lanes, :start_date, :end_date, :locked, :goal, :feedback_query)
      end

    end
  end
end
