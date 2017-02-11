class AddVisibilityToRoadmaps < ActiveRecord::Migration[5.0]
  def change
    add_column :roadmaps, :visibility, :string, null: false, default: "Team Members"
  end
end
