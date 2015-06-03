class AddTimestampsToRoadmapCommits < ActiveRecord::Migration
  def up
    add_column :roadmap_commits, :created_at, :timestamp
    add_column :roadmap_commits, :updated_at, :timestamp

    RoadmapCommit.find_each do |commit|
      version = commit.milestone_versions.first
      commit.update_column :created_at, version.created_at if version
      commit.update_column :updated_at, version.created_at if version
    end

    change_column_null :roadmap_commits, :created_at, false
    change_column_null :roadmap_commits, :updated_at, false
  end

  def down
    remove_column :roadmap_commits, :created_at
    remove_column :roadmap_commits, :updated_at
  end
end
