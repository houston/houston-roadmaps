class RoadmapCommit < ActiveRecord::Base
  attr_accessor :milestone_changes

  belongs_to :project
  belongs_to :user
  has_many :milestone_versions

  validates :user, :message, :project, :milestone_changes, presence: true

  after_save :commit_milestone_changes

private

  def commit_milestone_changes
    milestone_changes.each do |change|
      id = change.delete(:id)
      remove = change.delete(:removed)
      milestone = project.milestones.find_by_id(id)
      if remove
        milestone.update_attributes!(destroyed_at: Time.now) if milestone
      else
        if milestone
          milestone.update_attributes!(change)
        else
          milestone = project.create_milestone!(change.pick(:band, :lanes, :name, :start_date, :end_date))
        end
      end
      version = milestone.versions.at(milestone.version)
      version.update_column :roadmap_commit_id, self.id if version
    end
  end

end
