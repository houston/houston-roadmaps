class MilestoneVersion < VestalVersions::Version
  self.table_name = "milestone_versions"
  
  attr_accessor :user_name
  
  belongs_to :roadmap_commit
  
end
