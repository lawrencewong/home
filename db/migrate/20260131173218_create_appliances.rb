class CreateAppliances < ActiveRecord::Migration[8.1]
  def change
    create_table :appliances do |t|
      t.string :name, null: false
      t.string :location
      t.string :brand
      t.string :model_number
      t.string :serial_number
      t.date :purchase_date
      t.date :warranty_expires
      t.string :manual_url
      t.text :notes

      t.timestamps
    end
  end
end
