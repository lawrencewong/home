class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.string :title, null: false
      t.integer :status, default: 0, null: false
      t.text :notes
      t.date :due_date
      t.datetime :archived_at
      t.references :assigned_to, foreign_key: { to_table: :users }
      t.references :created_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :tasks, :status
    add_index :tasks, :due_date
  end
end
