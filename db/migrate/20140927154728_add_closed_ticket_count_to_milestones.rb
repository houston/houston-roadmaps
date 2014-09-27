class AddClosedTicketCountToMilestones < ActiveRecord::Migration
  def up
    add_column :milestones, :closed_tickets_count, :integer, null: false, default: 0
    Milestone.reset_column_information
    Milestone.find_each(&:update_closed_tickets_count!)
  end
  
  def down
    remove_column :milestones, :closed_tickets_count
  end
end
