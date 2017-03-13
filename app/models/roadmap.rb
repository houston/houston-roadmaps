class Roadmap < ActiveRecord::Base

  has_many :commits, -> { order(created_at: :asc) }, class_name: "RoadmapCommit"
  has_and_belongs_to_many :teams
  has_many :projects, -> { unretired.with_feature("goals") }, through: :teams do
    def goals
      Goal.where(project_id: unscope(:order, :select).select(:id)) +
        Milestone.where(project_id: unscope(:order, :select).select(:id))
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

      # Todo... is this right w/ the new commits?
      new_roadmap = self.class.create!(name: new_name, team_ids: team_ids)
      new_roadmap.commits.create!(
        user: as,
        message: "Created a copy of \"#{name}\"",
        milestone_changes: milestones
          .pluck(:milestone_id, :band, :lanes, :start_date, :end_date)
          .map { |milestone_id, band, lanes, start_date, end_date|
            { milestoneId: milestone_id,
              band: band,
              lanes: lanes,
              start_date: start_date,
              end_date: end_date } })
      new_roadmap
    end
  end

end
