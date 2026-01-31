class WishlistItemsController < ApplicationController
  before_action :set_wishlist_item, only: %i[show edit update destroy]

  def index
    @tab = params[:tab] || "purchases"
    @items = if @tab == "projects"
      WishlistItem.projects.by_priority
    else
      WishlistItem.purchases.by_priority
    end
    @total = WishlistItem.purchases.sum(:price) if @tab == "purchases"
  end

  def show
  end

  def new
    @wishlist_item = WishlistItem.new(item_type: params[:type] || :purchase)
  end

  def edit
  end

  def create
    @wishlist_item = WishlistItem.new(wishlist_item_params)
    @wishlist_item.created_by = Current.user

    if @wishlist_item.save
      redirect_to wishlist_items_path(tab: @wishlist_item.purchase? ? "purchases" : "projects"),
                  notice: "Item added to wishlist."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @wishlist_item.update(wishlist_item_params)
      redirect_to wishlist_items_path, notice: "Item updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @wishlist_item.destroy
    redirect_to wishlist_items_path, notice: "Item removed."
  end

  private

  def set_wishlist_item
    @wishlist_item = WishlistItem.find(params[:id])
  end

  def wishlist_item_params
    params.require(:wishlist_item).permit(:title, :item_type, :price, :priority, :notes, :link)
  end
end
