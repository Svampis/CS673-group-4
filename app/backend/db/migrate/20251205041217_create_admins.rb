class CreateAdmins < ActiveRecord::Migration[8.1]
  def change
    create_table :admins do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :fname
      t.string :lname
      t.string :number
      t.string :city
      t.string :street
      t.string :state

      t.timestamps
    end
  end
end
