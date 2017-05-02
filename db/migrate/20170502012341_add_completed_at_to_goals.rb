class AddCompletedAtToGoals < ActiveRecord::Migration[5.0]
  def change
    add_column :goals, :completed_at, :timestamp
  end
end
