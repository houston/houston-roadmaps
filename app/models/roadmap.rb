class Roadmap < ActiveRecord::Base

  has_many :milestones, class_name: "RoadmapMilestone"
  has_many :commits, class_name: "RoadmapCommit"
  has_and_belongs_to_many :projects

  validates :name, presence: true

end
