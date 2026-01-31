class WishlistItem < ApplicationRecord
  belongs_to :created_by, class_name: "User"

  enum :item_type, { purchase: 0, future_project: 1 }
  enum :priority, { low: 0, medium: 1, high: 2 }

  validates :title, presence: true
  validates :link, format: { with: /\Ahttps?:\/\/\S+\z/, message: "must be a valid HTTP or HTTPS URL" }, allow_blank: true

  def safe_link
    link if link.present? && link.match?(/\Ahttps?:\/\//)
  end

  scope :purchases, -> { where(item_type: :purchase) }
  scope :projects, -> { where(item_type: :future_project) }
  scope :by_priority, -> { order(priority: :desc, created_at: :desc) }
end
