class CreateWishlistItems < ActiveRecord::Migration[8.1]
  def change
    create_table :wishlist_items do |t|
      t.string :title, null: false
      t.integer :item_type, default: 0, null: false
      t.decimal :price, precision: 10, scale: 2
      t.integer :priority, default: 1, null: false
      t.text :notes
      t.string :link
      t.references :created_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :wishlist_items, :item_type
    add_index :wishlist_items, :priority
  end
end
