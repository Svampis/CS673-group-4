class CreateConversations < ActiveRecord::Migration[8.1]
  def change
    create_table :conversations do |t|
      t.references :participant1, null: false, foreign_key: { to_table: :users }
      t.references :participant2, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    # participant1_id and participant2_id are already indexed by references
    add_index :conversations, [:participant1_id, :participant2_id]
  end
end
