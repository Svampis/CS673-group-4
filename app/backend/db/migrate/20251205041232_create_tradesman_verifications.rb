class CreateTradesmanVerifications < ActiveRecord::Migration[8.1]
  def change
    create_table :tradesman_verifications do |t|
      t.references :tradesman, null: false, foreign_key: true
      t.string :status, default: 'pending'
      t.string :license_number
      t.text :certification_documents
      t.text :identification_documents
      t.references :admin, null: true, foreign_key: { to_table: :users }
      t.text :rejection_reason
      t.datetime :reviewed_at

      t.timestamps
    end

    # tradesman_id and admin_id are already indexed by references
    add_index :tradesman_verifications, :status
  end
end
