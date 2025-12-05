class CreateHomeowners < ActiveRecord::Migration[8.1]
  def change
    create_table :homeowners do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :fname
      t.string :lname
      t.string :number
      t.string :city
      t.string :street
      t.string :state
      t.decimal :latitude, precision: 10, scale: 8
      t.decimal :longitude, precision: 11, scale: 8

      t.timestamps
    end
  end
end
