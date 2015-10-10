class CreateRoadmapCommits < ActiveRecord::Migration
  def up
    create_table :roadmap_commits do |t|
      t.integer :user_id, null: false
      t.string :message, null: false
    end

    create_table :milestone_versions do |t|
      t.belongs_to :versioned, :polymorphic => true
      t.integer :roadmap_commit_id
      t.text    :modifications
      t.integer :number
      t.integer :reverted_from
      t.string  :tag

      t.timestamps

      t.index [:versioned_id, :versioned_type]
      t.index :roadmap_commit_id
      t.index :number
      t.index :created_at
    end
  end

  def down
    drop_table :roadmap_commits
    drop_table :milestone_versions
  end
end
