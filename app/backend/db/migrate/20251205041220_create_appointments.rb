class CreateAppointments < ActiveRecord::Migration[8.1]
  def change
    create_table :appointments do |t|
      t.references :homeowner, null: false, foreign_key: true
      t.references :project, null: true, foreign_key: true
      t.references :tradesman, null: false, foreign_key: true
      t.datetime :scheduled_start
      t.datetime :scheduled_end
      t.text :job_description
      t.string :status, default: 'pending'
      t.datetime :accepted_at
      t.datetime :rejected_at
      t.text :rejection_reason

      t.timestamps
    end

    # homeowner_id, tradesman_id, and project_id are already indexed by references
    add_index :appointments, :status
    add_index :appointments, :scheduled_start
  end
end
