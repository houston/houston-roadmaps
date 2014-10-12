class AddUserIdToMilestoneVersions < ActiveRecord::Migration
  def up
    add_column :milestone_versions, :user_id, :integer
    add_column :milestone_versions, :user_type, :string
  end
  
  def down
    remove_column :milestone_versions, :user_id
    remove_column :milestone_versions, :user_type
  end
end
