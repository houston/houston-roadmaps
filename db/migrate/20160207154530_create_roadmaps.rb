require "progressbar"

class CreateRoadmaps < ActiveRecord::Migration
  def up
    create_table :roadmaps do |t|
      t.string :name, null: false
    end

    # Roadmaps can be tied to more than one Project
    create_table :projects_roadmaps, id: false do |t|
      t.integer :project_id, null: false
      t.integer :roadmap_id, null: false
      t.index [:project_id, :roadmap_id], unique: true
    end

    # RoadmapCommits will belong to Roadmaps now, not to Projects
    add_column :roadmap_commits, :roadmap_id, :integer
    change_column_null :roadmap_commits, :project_id, true

    # Milestones can belong to more than one Roadmap
    # The RoadmapMilestone model will wrap Milestone
    # and add band, lanes, start_date, and end_date.
    #
    # After this, we can drop those columns from Milestone,
    # drop MilestoneVersion, and let houston-core implement
    # versioning on Milestones in a more general-purpose
    # way.
    create_table :roadmap_milestones do |t|
      t.integer :milestone_id, null: false
      t.integer :roadmap_id, null: false
      t.integer :band, null: false, default: 1
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.integer :lanes, null: false, default: 1
      t.timestamp :destroyed_at
      t.index [:milestone_id, :roadmap_id], unique: true
    end

    # We need to version RoadmapMilestones, not Milestones
    create_table :roadmap_milestone_versions do |t|
      t.belongs_to :versioned, :polymorphic => true
      t.integer :roadmap_commit_id
      t.text    :modifications
      t.integer :number
      t.integer :reverted_from
      t.string  :tag
      t.integer :user_id
      t.string  :user_type

      t.timestamps

      t.index [:versioned_id, :versioned_type], name: "index_roadmap_milestone_versions_on_versioned"
      t.index :roadmap_commit_id
      t.index :number
      t.index :created_at
    end

    # Create a Roadmap for every project that has roadmapped milestones
    milestones = Milestone.arel_table
    roadmapped_milestones = Milestone.unscoped
      .where(milestones[:band].not_eq(nil))
      .where(milestones[:lanes].not_eq(nil))
      .where(milestones[:start_date].not_eq(nil))
      .where(milestones[:end_date].not_eq(nil))
    projects = Project.where(id: roadmapped_milestones.select(:project_id))

    pbar = ProgressBar.new("roadmaps", projects.count)
    projects.find_each do |project|
      roadmap = Roadmap.create!(name: project.name, project_ids: [project.id])

      # Associate Milestones with the Roadmap
      # by creating RoadmapMilestones to wrap each
      # Milestone that has time frame.
      RoadmapMilestone.import [:roadmap_id, :milestone_id, :band, :start_date, :end_date, :lanes, :destroyed_at],
        roadmapped_milestones
          .where(project_id: project.id)
          .pluck(:id, :band, :start_date, :end_date, :lanes, :destroyed_at)
          .map { |attrs| [roadmap.id, *attrs] }

      # Associate RoadmapCommits with the Roadmap
      RoadmapCommit.where(project_id: project.id).update_all(roadmap_id: roadmap.id)

      # Convert MilestoneVersions to RoadmapMilestoneVersions
      new_versions = RoadmapMilestone.where(roadmap_id: roadmap.id)
        .pluck(:milestone_id, :id)
        .uniq
        .flat_map do |milestone_id, roadmap_milestone_id|
        MilestoneVersion.where(versioned_id: milestone_id)
          .pluck(*VERSION_ATTRIBUTES)
          .map { |attrs| [roadmap_milestone_id, *attrs] }
      end
      RoadmapMilestoneVersion.import [:versioned_id, *VERSION_ATTRIBUTES], new_versions

      pbar.inc
    end
    pbar.finish
  end

  def down
    RoadmapCommit.where(project_id: nil).delete_all
    change_column_null :roadmap_commits, :project_id, false
    remove_column :roadmap_commits, :roadmap_id
    drop_table :projects_roadmaps
    drop_table :roadmap_milestone_versions
    drop_table :roadmap_milestones
    drop_table :roadmaps
  end

  VERSION_ATTRIBUTES = %i{
    versioned_type
    roadmap_commit_id
    modifications
    number
    reverted_from
    tag
    created_at
    updated_at
    user_id
    user_type }.freeze

  class MilestoneVersion < VestalVersions::Version
    self.table_name = "milestone_versions"
  end

end
