class RoadmapMilestone < ActiveRecord::Base

  default_scope { where(destroyed_at: nil).preload(:milestone) }

  belongs_to :roadmap
  belongs_to :milestone, -> { unscope(where: :destroyed_at) }

  validates :roadmap_id, :milestone_id, :band, :start_date, :end_date, :lanes, presence: true

  versioned only: [:start_date, :end_date, :band, :lanes, :destroyed_at], class_name: "RoadmapMilestoneVersion", initial_version: true

  delegate :project,
           :project_id,
           :name,
           :completed?,
           to: :milestone


  class << self
    def including_destroyed
      unscope(where: :destroyed_at)
    end

    def during(range)
      where(arel_table[:start_date].lteq(range.end)).where(arel_table[:end_date].gteq(range.begin))
    end

    def current
      during Date.today..Date.today
    end
  end

  def update_name!(name)
    milestone.update_attributes! name: name
  end

end
