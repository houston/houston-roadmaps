class AddLockedToMilestone < ActiveRecord::Migration
  def change
    add_column :milestones, :locked, :boolean, null: false, default: false
  end
end
