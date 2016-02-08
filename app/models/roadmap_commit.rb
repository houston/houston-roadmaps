class RoadmapCommit < ActiveRecord::Base
  attr_accessor :milestone_changes

  belongs_to :roadmap
  belongs_to :user
  has_many :milestone_versions, class_name: "RoadmapMilestoneVersion"

  validates :user, :message, :roadmap, :milestone_changes, presence: true

  after_save :commit_milestone_changes

private

  def commit_milestone_changes
    milestone_changes.each do |change|
      id = change.delete(:id)
      remove = change.delete(:removed)
      milestone = id && roadmap.milestones.find_by_id(id)
      if remove == true || remove == "true"
        milestone.update_attributes!(destroyed_at: Time.now) if milestone
      else
        milestone_attributes = change.pick(:band, :lanes, :start_date, :end_date)
        if milestone
          milestone.update_attributes!(milestone_attributes)
        else
          milestone = roadmap.milestones.create!(
            milestone_attributes.merge(milestone_id: change[:milestoneId]))
        end
      end
      version = milestone.versions.at(milestone.version)
      version.update_column :roadmap_commit_id, self.id if version
    end
  end

end
