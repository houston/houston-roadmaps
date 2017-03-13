class RoadmapCommit < ActiveRecord::Base
  class BadDiffError < RuntimeError; end

  belongs_to :roadmap
  belongs_to :user

  # DEPRECATED: remove this association
  has_many :milestone_versions, class_name: "RoadmapMilestoneVersion"

  validates :user, :message, :roadmap, presence: true
  validates :diffs, length: { minimum: 1 }

  def milestones
    roadmap.commits
      .take_while { |commit| commit.created_at <= created_at }
      .each_with_object({}) do |commit, milestones_by_id|

      commit.diffs.each do |diff|
        status = diff.fetch("status")
        milestone_type = diff.fetch("milestone_type", "Milestone")
        milestone_id = diff.fetch("milestone_id")
        attributes = diff.fetch("attributes", {})
        key = [milestone_type, milestone_id].join("/")

        case status
        when "added" then milestones_by_id[key] = attributes.merge("id" => milestone_id, "type" => milestone_type)
        when "deleted" then milestones_by_id.delete(key)
        when "modified" then milestones_by_id[key].merge! attributes
        else raise BadDiffError
        end
      end
    end.values
  end

  def milestone_changes=(changes)
    current_milestones = roadmap.milestones
    diffs = []
    changes.each do |change|
      removed = change[:removed].to_s == "true"

      new_attributes = change.each_with_object({}) do |(key, value), attributes|
        next unless %w{name band lanes start_date end_date}.member? key
        value = value.to_date if %w{start_date end_date}.member?(key)
        value = value.to_i if %w{band lanes}.member?(key)
        attributes[key] = value
      end

      if !change.key?(:id)
        next if removed

        if change.key?(:name) && change.key?(:projectId) && !change.key?(:newId)
          project = Project.find(change[:projectId])
          goal = project.goals.create!(name: change[:name])
          change = change.merge(newId: goal.id, newType: "Goal")
        end

        if change.key?(:newId) && change.key?(:newType)
          id = change.fetch(:newId).to_i
          type = change.fetch(:newType)
          diffs.push milestone_id: id, milestone_type: type, status: "added", attributes: new_attributes
        end

        next
      end

      id = change.fetch(:id).to_i
      type = change.fetch(:type)
      current_attributes = current_milestones.find { |attributes| attributes["id"] == id && attributes["type"] == type }

      if removed
        diffs.push milestone_id: id, milestone_type: type, status: "deleted" if current_attributes
      elsif current_attributes
        differences = new_attributes.select { |attribute, new_value| new_value != current_attributes[attribute] }
        diffs.push milestone_id: id, milestone_type: type, status: "modified", attributes: differences
      else
        binding.pry # <-- unexpected
      end
    end

    self.diffs = diffs
  end

end
