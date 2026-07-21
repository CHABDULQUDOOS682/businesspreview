module Admin
  class PortfolioItemsController < ApplicationController
    layout "admin"
    before_action :require_admin_or_super_admin!
    before_action :set_portfolio_item, only: [ :edit, :update, :destroy, :toggle_active ]

    def index
      @portfolio_items = PortfolioItem.order(:position, :created_at)
    end

    def new
      @portfolio_item = PortfolioItem.new(active: true, accent_color: PortfolioItem::ACCENT_COLORS.first)
    end

    def edit
    end

    def create
      @portfolio_item = PortfolioItem.new(portfolio_item_params)

      if @portfolio_item.save
        redirect_to admin_portfolio_items_path, notice: "Portfolio item was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @portfolio_item.update(portfolio_item_params)
        purge_image_if_requested!
        redirect_to admin_portfolio_items_path, notice: "Portfolio item was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @portfolio_item.destroy
      redirect_to admin_portfolio_items_path, notice: "Portfolio item was successfully destroyed."
    end

    def toggle_active
      @portfolio_item.update(active: !@portfolio_item.active)
      redirect_to admin_portfolio_items_path, notice: "Portfolio item is now #{@portfolio_item.active? ? 'visible' : 'hidden'}."
    end

    private

    def set_portfolio_item
      @portfolio_item = PortfolioItem.find(params[:id])
    end

    def portfolio_item_params
      params.require(:portfolio_item).permit(
        :title, :category, :description, :metric, :accent_color, :position, :active,
        :link_url, :image
      )
    end

    def purge_image_if_requested!
      return if params.dig(:portfolio_item, :image).present?
      return unless ActiveModel::Type::Boolean.new.cast(params.dig(:portfolio_item, :remove_image))
      return unless @portfolio_item.image.attached?

      @portfolio_item.image.purge
    end
  end
end
