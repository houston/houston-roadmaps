class AddEndDateToMilestones < ActiveRecord::Migration
  def up
    add_column :milestones, :end_date, :date
    execute <<-SQL
      UPDATE milestones
        SET end_date=start_date + (size || ' ' || units)::interval - '2 days'::interval
      WHERE start_date IS NOT NULL
        AND size IS NOT NULL
        AND units IS NOT NULL
    SQL
  end

  def down
    remove_column :milestones, :end_date
  end
end
