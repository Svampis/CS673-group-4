class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :notification_type
      t.string :title
      t.text :message
      t.boolean :read, default: false
      t.datetime :read_at
      t.integer :related_id
      t.string :related_type

      t.timestamps
    end

    # user_id is already indexed by references
    add_index :notifications, :read
    add_index :notifications, [:user_id, :read]
    add_index :notifications, :related_id
    add_index :notifications, :related_type
  end
end
