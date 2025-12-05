class CreateReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :reviews do |t|
      t.references :homeowner, null: false, foreign_key: true
      t.references :tradesman, null: false, foreign_key: true
      t.references :appointment, null: true, foreign_key: true
      t.integer :rating
      t.text :comment

      t.timestamps
    end

    # homeowner_id, tradesman_id, and appointment_id are already indexed by references
  end
end
