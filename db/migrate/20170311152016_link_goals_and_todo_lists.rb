class LinkGoalsAndTodoLists < ActiveRecord::Migration[5.0]
  def change
    create_join_table :todo_lists, :goals
    add_foreign_key :goals_todo_lists, :goals, on_delete: :cascade
    add_foreign_key :goals_todo_lists, :todo_lists, on_delete: :cascade
    add_index :goals_todo_lists, [:goal_id, :todo_list_id], unique: true
  end
end
