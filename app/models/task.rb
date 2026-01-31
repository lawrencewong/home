class Task < ApplicationRecord
  belongs_to :assigned_to, class_name: "User", optional: true
  belongs_to :created_by, class_name: "User"

  enum :status, { todo: 0, in_progress: 1, done: 2 }

  validates :title, presence: true

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }
  scope :overdue, -> { where("due_date < ?", Date.current).where.not(status: :done) }
  scope :assigned_to_user, ->(user) { where(assigned_to: user) }

  def overdue?
    due_date.present? && due_date < Date.current && !done?
  end
end
