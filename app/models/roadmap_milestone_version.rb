class RoadmapMilestoneVersion < VestalVersions::Version
  self.table_name = "roadmap_milestone_versions"

  attr_accessor :user_name

  belongs_to :roadmap_commit

end
