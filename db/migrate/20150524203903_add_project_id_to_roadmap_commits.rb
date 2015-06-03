class AddProjectIdToRoadmapCommits < ActiveRecord::Migration
  def up
    add_column :roadmap_commits, :project_id, :integer

    RoadmapCommit.find_each do |commit|
      version = commit.milestone_versions.first
      milestone = version.versioned if version
      commit.update_column :project_id, milestone.project_id if milestone
    end

    change_column_null :roadmap_commits, :project_id, false
  end

  def down
    remove_column :roadmap_commits, :project_id
  end
end
