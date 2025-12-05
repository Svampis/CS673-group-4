class CreateProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :projects do |t|
      t.references :contractor, null: true, foreign_key: { to_table: :users }
      t.references :homeowner, null: true, foreign_key: true
      t.string :title
      t.text :description
      t.string :trade_type
      t.decimal :budget
      t.text :location
      t.decimal :latitude, precision: 10, scale: 8
      t.decimal :longitude, precision: 11, scale: 8
      t.date :preferred_date
      t.string :status, default: 'open'
      t.references :assigned, null: true, foreign_key: { to_table: :tradesmen }
      t.decimal :bidding_increments
      t.string :timespan
      t.text :requirements

      t.timestamps
    end

    # contractor_id and homeowner_id are already indexed by references
    add_index :projects, :trade_type
    add_index :projects, :status
  end
end
