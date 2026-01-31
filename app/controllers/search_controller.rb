class SearchController < ApplicationController
  def index
    @query = params[:q].to_s.strip
    return if @query.blank?

    @tasks = Task.active.where("title LIKE ? OR notes LIKE ?", "%#{@query}%", "%#{@query}%").limit(10)
    @appliances = Appliance.where("name LIKE ? OR brand LIKE ? OR notes LIKE ?",
      "%#{@query}%", "%#{@query}%", "%#{@query}%").limit(10)
    @wishlist_items = WishlistItem.where("title LIKE ? OR notes LIKE ?", "%#{@query}%", "%#{@query}%").limit(10)
  end
end
