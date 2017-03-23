class ConvertMilestoneToGoal
  attr_reader :milestone

  def self.perform!(milestone)
    self.new(milestone).perform!
  end

  def initialize(milestone)
    @milestone = milestone
  end

  def perform!
    ActiveRecord::Base.transaction do
      # 1. Create a Goal that's a copy of the Milestone
      goal = milestone.project.goals.create!(name: milestone.name)

      # 2. Rewrite every RoadmapCommit that refers to the Milestone to refer to the Goal
      RoadmapCommit.find_each do |commit|
        diffs = commit.diffs
        changes = 0
        diffs.each do |diff|
          next unless diff.fetch("milestone_type", "Milestone") == "Milestone"
          next unless diff.fetch("milestone_id") == milestone.id
          diff["milestone_type"] = "Goal"
          diff["milestone_id"] = goal.id
          changes += 1
        end
        commit.update_attribute :diffs, diffs if changes > 0
      end

      # 3. Delete the Milestone
      milestone.destroy

      goal
    end
  end

end
