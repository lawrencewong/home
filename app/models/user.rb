class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :assigned_tasks, class_name: "Task", foreign_key: :assigned_to_id
  has_many :created_tasks, class_name: "Task", foreign_key: :created_by_id
  has_many :wishlist_items, foreign_key: :created_by_id

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
