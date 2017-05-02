class Goal < ActiveRecord::Base

  belongs_to :project
  has_and_belongs_to_many :todolists, join_table: "goals_todo_lists", class_name: "TodoList"

  default_scope { where(destroyed_at: nil) }

  def closed?
    !open?
  end
  alias :completed? :closed?

  def open?
    completed_at.nil?
  end

  def closed=(value)
    if value
      self.completed_at = Time.now if open?
    else
      self.completed_at = nil
    end
  end

end
