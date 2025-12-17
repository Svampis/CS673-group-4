class CreateBids < ActiveRecord::Migration[8.1]
  def change
    create_table :bids do |t|
      t.string :position_description
      t.references :project_id, null: false, foreign_key: { to_table: :projects }
      t.references :bidder_id, null: false, foreign_key: { to_table: :users }
      t.integer :bid_amount

      t.timestamps
    end
  end
end
