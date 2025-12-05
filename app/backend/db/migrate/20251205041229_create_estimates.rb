class CreateEstimates < ActiveRecord::Migration[8.1]
  def change
    create_table :estimates do |t|
      t.references :appointment, null: true, foreign_key: true
      t.references :project, null: true, foreign_key: true
      t.references :tradesman, null: false, foreign_key: true
      t.references :homeowner, null: false, foreign_key: true
      t.decimal :amount
      t.string :status, default: 'pending'
      t.integer :version, default: 1
      t.text :notes

      t.timestamps
    end

    # tradesman_id, homeowner_id, appointment_id, and project_id are already indexed by references
    add_index :estimates, :status
  end
end
