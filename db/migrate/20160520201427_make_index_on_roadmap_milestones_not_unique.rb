class MakeIndexOnRoadmapMilestonesNotUnique < ActiveRecord::Migration
  def up
    remove_index :roadmap_milestones, [:milestone_id, :roadmap_id]
    add_index :roadmap_milestones, [:milestone_id, :roadmap_id]
  end

  def down
    remove_index :roadmap_milestones, [:milestone_id, :roadmap_id]
    add_index :roadmap_milestones, [:milestone_id, :roadmap_id], unique: true
  end
end
