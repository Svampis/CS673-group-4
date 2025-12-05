class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: true
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.text :content
      t.string :attachment
      t.datetime :read_at

      t.timestamps
    end

    # conversation_id and sender_id are already indexed by references
    add_index :messages, :created_at
  end
end
