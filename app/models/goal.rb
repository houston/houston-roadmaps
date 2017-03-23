class Goal < ActiveRecord::Base

  belongs_to :project
  has_and_belongs_to_many :todolists, join_table: "goals_todo_lists", class_name: "TodoList"

  default_scope { where(destroyed_at: nil) }

  def completed?
    false
  end

end
