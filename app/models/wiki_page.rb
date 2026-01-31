class WikiPage < ApplicationRecord
  belongs_to :created_by, class_name: "User"
  belongs_to :updated_by, class_name: "User"

  validates :title, presence: true, uniqueness: { case_sensitive: false }

  before_save :normalize_title

  def self.find_by_title(title)
    find_by("LOWER(title) = ?", title.downcase)
  end

  def rendered_body
    return "" if body.blank?

    # Convert [[Page Title]] links to actual links
    linked_body = body.gsub(/\[\[([^\]]+)\]\]/) do |_match|
      page_title = ::Regexp.last_match(1)
      if WikiPage.find_by_title(page_title)
        "[#{page_title}](/wiki_pages/#{CGI.escape(page_title)})"
      else
        "[#{page_title}?](/wiki_pages/new?title=#{CGI.escape(page_title)})"
      end
    end

    markdown = Redcarpet::Markdown.new(
      Redcarpet::Render::HTML.new(hard_wrap: true),
      autolink: true,
      tables: true,
      fenced_code_blocks: true
    )
    markdown.render(linked_body).html_safe
  end

  private

  def normalize_title
    self.title = title.strip if title.present?
  end
end
