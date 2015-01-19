class AddGoalAndFeedbackQueryToMilestones < ActiveRecord::Migration
  def change
    add_column :milestones, :goal, :text
    add_column :milestones, :feedback_query, :string
  end
end
