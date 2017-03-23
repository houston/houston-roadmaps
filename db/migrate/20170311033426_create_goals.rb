class CreateGoals < ActiveRecord::Migration[5.0]
  def change
    create_table :goals do |t|
      t.belongs_to :project, foreign_key: true, index: true
      t.string :name, null: false
      t.jsonb :props, null: false, default: {}

      t.timestamp :destroyed_at
      t.timestamps
    end
  end
end
