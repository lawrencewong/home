class Appliance < ApplicationRecord
  has_many :reminders, as: :remindable, dependent: :nullify

  validates :name, presence: true
  validates :manual_url, format: { with: /\Ahttps?:\/\/\S+\z/, message: "must be a valid HTTP or HTTPS URL" }, allow_blank: true

  def safe_manual_url
    manual_url if manual_url.present? && manual_url.match?(/\Ahttps?:\/\//)
  end

  def warranty_status
    return :none unless warranty_expires

    if warranty_expires < Date.current
      :expired
    elsif warranty_expires < 6.months.from_now
      :warning
    else
      :ok
    end
  end

  def warranty_status_class
    case warranty_status
    when :ok then "warranty-ok"
    when :warning then "warranty-warning"
    when :expired then "warranty-expired"
    else ""
    end
  end
end
