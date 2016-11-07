class Roadmap < ActiveRecord::Base

  has_many :milestones, class_name: "RoadmapMilestone"
  has_many :commits, class_name: "RoadmapCommit"
  has_and_belongs_to_many :teams
  has_many :projects, -> { unretired.with_feature("goals") }, through: :teams

  validates :name, presence: true

end
