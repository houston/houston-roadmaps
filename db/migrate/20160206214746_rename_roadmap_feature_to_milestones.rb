require "progressbar"

class RenameRoadmapFeatureToMilestones < ActiveRecord::Migration
  def up
    projects = Project.with_feature("roadmap")
    pbar = ProgressBar.new("projects", projects.count)
    projects.find_each do |project|
      project.update_column :selected_features,
        (project.selected_features.map(&:to_sym) - %i{roadmap} + %i{goals}).uniq
      pbar.inc
    end
    pbar.finish
  end

  def down
    projects = Project.with_feature("milestones")
    pbar = ProgressBar.new("projects", projects.count)
    projects.find_each do |project|
      project.update_column :selected_features,
        (project.selected_features.map(&:to_sym) - %i{goals} + %i{roadmap}).uniq
      pbar.inc
    end
    pbar.finish
  end
end
