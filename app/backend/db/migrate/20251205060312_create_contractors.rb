class CreateContractors < ActiveRecord::Migration[8.1]
  def change
    create_table :contractors do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string "fname"
      t.string "lname"
      t.string "street"
      t.string "city"
      t.string "state"
      t.string "number"
      t.decimal "latitude", precision: 10, scale: 8
      t.decimal "longitude", precision: 11, scale: 8

      t.timestamps
    end
  end
end
