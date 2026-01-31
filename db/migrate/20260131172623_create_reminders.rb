class CreateReminders < ActiveRecord::Migration[8.1]
  def change
    create_table :reminders do |t|
      t.string :title, null: false
      t.date :due_date, null: false
      t.string :recurrence_rule
      t.datetime :completed_at
      t.references :remindable, polymorphic: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :reminders, :due_date
    add_index :reminders, :completed_at
  end
end
