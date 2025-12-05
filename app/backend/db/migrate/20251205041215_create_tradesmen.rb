class CreateTradesmen < ActiveRecord::Migration[8.1]
  def change
    create_table :tradesmen do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :fname
      t.string :lname
      t.string :number
      t.string :city
      t.string :street
      t.string :state
      t.string :description
      t.string :trade_specialty
      t.decimal :service_radius
      t.decimal :hourly_rate
      t.string :license_number
      t.string :business_name
      t.integer :years_of_experience
      t.text :certification_documents
      t.text :photos
      t.string :verification_status, default: 'pending'
      t.decimal :latitude, precision: 10, scale: 8
      t.decimal :longitude, precision: 11, scale: 8

      t.timestamps
    end

    add_index :tradesmen, :trade_specialty
    add_index :tradesmen, :verification_status
  end
end
