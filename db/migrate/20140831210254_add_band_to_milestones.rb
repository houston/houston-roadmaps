class AddBandToMilestones < ActiveRecord::Migration
  def change
    add_column :milestones, :band, :integer, null: false, default: 1
  end
end
