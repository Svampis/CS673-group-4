class CreateBids < ActiveRecord::Migration[8.1]
  def change
    create_table :bids do |t|
      t.references :project, null: false, foreign_key: true
      t.references :tradesman, null: false, foreign_key: true
      t.references :appointment, null: true, foreign_key: true
      t.decimal :amount
      t.decimal :hourly_rate
      t.string :status, default: 'pending'
      t.decimal :bidding_increment

      t.timestamps
    end

    # project_id, tradesman_id, and appointment_id are already indexed by references
    add_index :bids, :status
  end
end
