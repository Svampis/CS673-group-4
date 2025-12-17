class CreateAppointments < ActiveRecord::Migration[8.1]
  def change
    create_table :appointments do |t|
      t.references :worker, null: false, foreign_key: { to_table: :users }
      t.references :customer, null: false, foreign_key: { to_table: :users }
      t.datetime :start_time
      t.datetime :end_time

      t.timestamps
    end
  end
end
