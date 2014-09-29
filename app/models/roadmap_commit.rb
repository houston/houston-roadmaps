class RoadmapCommit < ActiveRecord::Base
  attr_accessor :milestone_changes, :project
  
  belongs_to :user
  has_many :milestone_versions
  
  validates :user, :message, :milestone_changes, presence: true
  
  after_save :commit_milestone_changes
  
private
  
  def commit_milestone_changes
    milestone_changes.each do |change|
      milestone = project.milestones.find(change.delete(:id))
      milestone.update_attributes!(change)
      version = milestone.versions.at(milestone.version)
      version.update_column :roadmap_commit_id, id
    end
  end
  
end
