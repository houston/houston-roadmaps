module Houston
  module Roadmap
    class MilestonesController < ApplicationController
      attr_reader :milestone
      
      layout "houston/roadmap/application"
      
      before_filter :find_milestone, only: [:show, :update, :close, :add_ticket, :remove_ticket]
      
      
      def show
        authorize! :read, milestone
        @project = milestone.project
        @title = "#{milestone.name} • #{@project.name}"
        @tickets = milestone.tickets.includes(:tasks, :reporter)
        @open_tickets = @project.tickets.open.includes(:tasks, :reporter)
      end
      
      
      def create
        project = Project.find(params[:projectId])
        authorize! :create, project.milestones.build
        milestone = project.create_milestone!(milestone_attributes)
        if milestone.persisted?
          render json: Houston::Roadmap::MilestonePresenter.new(milestone), status: :created
        else
          render json: milestone.errors, status: :unprocessable_entity
        end
      end
      
      
      def update
        authorize! :update, milestone
        milestone.updated_by = current_user
        if milestone.update_attributes(milestone_attributes)
          render json: Houston::Roadmap::MilestonePresenter.new(milestone)
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
        authorize! :update, milestone
        ticket = Ticket.find params[:ticket_id]
        ticket.update_attribute :milestone_id, milestone.id
        head :ok
      end
      
      
      def remove_ticket
        authorize! :update, milestone
        ticket = Ticket.find params[:ticket_id]
        ticket.update_attribute :milestone_id, nil
        head :ok
      end
      
      
    private
      
      def find_milestone
        @milestone = Milestone.unscoped.find(params[:id])
      end
      
      def milestone_attributes
        params.fetch(:milestone).pick(:name, :band, :size, :units, :start_date)
      end
      
    end
  end
end
