class WikiPagesController < ApplicationController
  before_action :set_wiki_page, only: %i[show edit update destroy]

  def index
    @wiki_pages = WikiPage.order(:title)
  end

  def show
  end

  def new
    @wiki_page = WikiPage.new(title: params[:title])
  end

  def edit
  end

  def create
    @wiki_page = WikiPage.new(wiki_page_params)
    @wiki_page.created_by = Current.user
    @wiki_page.updated_by = Current.user

    if @wiki_page.save
      redirect_to wiki_page_path(@wiki_page.title), notice: "Page created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @wiki_page.updated_by = Current.user
    if @wiki_page.update(wiki_page_params)
      redirect_to wiki_page_path(@wiki_page.title), notice: "Page updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @wiki_page.destroy
    redirect_to wiki_pages_path, notice: "Page deleted."
  end

  private

  def set_wiki_page
    @wiki_page = WikiPage.find_by_title(params[:id]) || WikiPage.find(params[:id])
  end

  def wiki_page_params
    params.require(:wiki_page).permit(:title, :body)
  end
end
