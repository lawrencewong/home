class CreateWikiPages < ActiveRecord::Migration[8.1]
  def change
    create_table :wiki_pages do |t|
      t.string :title, null: false
      t.text :body
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :updated_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :wiki_pages, :title, unique: true
  end
end
