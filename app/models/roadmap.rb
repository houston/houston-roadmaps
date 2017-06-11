class Roadmap < ActiveRecord::Base

  has_many :commits, -> { order(created_at: :asc) }, class_name: "RoadmapCommit"
  has_and_belongs_to_many :teams
  has_many :projects, -> { unretired.with_feature("goals") }, through: :teams do
    def goals
      Goal.where(project_id: unscope(:order, :select).select(:id)).open +
        Milestone.where(project_id: unscope(:order, :select).select(:id)).open
    end
  end

  validates :name, presence: true

  VISIBILITY = ["Everyone", "Team Members", "Team Owners"].freeze

  validates :visibility, presence: true, inclusion: { in: VISIBILITY }


  def milestones
    return [] if commits.none?
    commits.last.milestones
  end

  def duplicate!(as:)
    Roadmap.transaction do
      base_name = name.gsub(/\s*\(\d+\)$/, "")
      newest_copy = self.class.where("name ~ ?", "#{base_name} \\(\\d+\\)").reorder(name: :desc).limit(1).pluck(:name).first
      copy_number = newest_copy ? newest_copy[/\((\d+)\)$/, 1].to_i + 1 : 1
      new_name = "#{base_name} (#{copy_number})"

      new_roadmap = self.class.create!(name: new_name, team_ids: team_ids)
      new_roadmap.commits.create!(
        roadmap: new_roadmap,
        user: as,
        message: "Created a copy of \"#{name}\"",
        milestone_changes: milestones.map { |milestone|
          { newId: milestone["id"],
            newType: milestone["type"],
            name: milestone["name"],
            band: milestone["band"],
            lanes: milestone["lanes"],
            start_date: milestone["start_date"],
            end_date: milestone["end_date"] }.with_indifferent_access })
      new_roadmap
    end
  end

end
