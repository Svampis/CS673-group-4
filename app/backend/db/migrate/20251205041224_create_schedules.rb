class CreateSchedules < ActiveRecord::Migration[8.1]
  def change
    create_table :schedules do |t|
      t.references :tradesman, null: false, foreign_key: true
      t.date :date
      t.time :start_time
      t.time :end_time
      t.string :status, default: 'available'

      t.timestamps
    end

    # tradesman_id is already indexed by references
    add_index :schedules, :date
    add_index :schedules, [:tradesman_id, :date]
  end
end
