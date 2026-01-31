class Reminder < ApplicationRecord
  belongs_to :remindable, polymorphic: true, optional: true
  belongs_to :created_by, class_name: "User"

  validates :title, presence: true
  validates :due_date, presence: true

  scope :pending, -> { where(completed_at: nil) }
  scope :completed, -> { where.not(completed_at: nil) }
  scope :overdue, -> { pending.where("due_date < ?", Date.current) }
  scope :upcoming, ->(days = 7) { pending.where(due_date: Date.current..days.days.from_now) }
  scope :by_due_date, -> { order(:due_date) }

  RECURRENCE_RULES = %w[daily weekly monthly yearly].freeze

  def overdue?
    completed_at.nil? && due_date < Date.current
  end

  def recurring?
    recurrence_rule.present?
  end

  def complete!
    transaction do
      update!(completed_at: Time.current)
      create_next_occurrence if recurring?
    end
  end

  private

  def create_next_occurrence
    next_date = calculate_next_date
    return unless next_date

    Reminder.create!(
      title: title,
      due_date: next_date,
      recurrence_rule: recurrence_rule,
      remindable: remindable,
      created_by: created_by
    )
  end

  def calculate_next_date
    case recurrence_rule
    when "daily"
      due_date + 1.day
    when "weekly"
      due_date + 1.week
    when "monthly"
      due_date + 1.month
    when "yearly"
      due_date + 1.year
    end
  end
end
