class AddLanesToMilestones < ActiveRecord::Migration
  def change
    add_column :milestones, :lanes, :integer, null: false, default: 1
  end
end
