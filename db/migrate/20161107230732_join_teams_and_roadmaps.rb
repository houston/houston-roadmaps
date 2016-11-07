class JoinTeamsAndRoadmaps < ActiveRecord::Migration
  def up
    Roadmap.class_eval <<-RUBY
      has_and_belongs_to_many :projects
    RUBY

    # Roadmaps can be tied to more than one Team
    create_table :roadmaps_teams, id: false do |t|
      t.integer :team_id, null: false
      t.integer :roadmap_id, null: false
      t.index [:team_id, :roadmap_id], unique: true
    end

    Roadmap.find_each do |roadmap|
      team_ids = Team.joins(:projects).where(Project.arel_table[:id].in(roadmap.project_ids)).pluck(:id).uniq
      roadmap.team_ids = team_ids
    end
  end

  def down
    drop_table :roadmaps_teams
  end
end
