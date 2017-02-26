class RoadmapCommit < ActiveRecord::Base
  class BadDiffError < RuntimeError; end

  belongs_to :roadmap
  belongs_to :user

  # DEPRECATED: remove this association
  has_many :milestone_versions, class_name: "RoadmapMilestoneVersion"

  validates :user, :message, :roadmap, presence: true
  validates :diffs, length: { minimum: 1 }

  def milestones
    roadmap.commits.take_while { |commit| commit.created_at <= created_at }.each_with_object({}) do |commit, milestones_by_id|
      commit.diffs.each do |diff|
        status = diff.fetch("status")
        milestone_id = diff.fetch("milestone_id")
        attributes = diff.fetch("attributes", {})

        case status
        when "added" then milestones_by_id[milestone_id] = attributes.merge("id" => milestone_id)
        when "deleted" then milestones_by_id.delete(milestone_id)
        when "modified" then milestones_by_id[milestone_id].merge! attributes
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
        if change.key?(:name) && change.key?(:projectId)
          project = Project.find(change[:projectId])
          project_milestone = project.create_milestone!(name: change[:name])
          change[:milestoneId] = project_milestone.id
        end

        next unless change.key?(:milestoneId)
        next if removed

        id = change.fetch(:milestoneId).to_i
        diffs.push milestone_id: id, status: "added", attributes: new_attributes
        next
      end

      id = change.fetch(:id).to_i
      current_attributes = current_milestones.find { |attributes| attributes["id"] == id }

      if removed
        diffs.push milestone_id: id, status: "deleted" if current_attributes
      elsif current_attributes
        differences = new_attributes.select { |attribute, new_value| new_value != current_attributes[attribute] }
        diffs.push milestone_id: id, status: "modified", attributes: differences
      else
        binding.pry
        diffs.push milestone_id: id, status: "added", attributes: new_attributes
      end
    end

    self.diffs = diffs
  end

end
