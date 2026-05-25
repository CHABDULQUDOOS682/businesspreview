module Admin
  class ReviewsController < ApplicationController
    layout "admin"
    before_action :set_review, only: [ :show, :edit, :update, :destroy ]

    def index
      @reviews = Review.all.order(created_at: :desc)
    end

    def show
    end

    def new
      @review = Review.new
    end

    def edit
    end

    def create
      @review = Review.new(review_params)

      if @review.save
        redirect_to admin_reviews_path, notice: "Review was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @review.update(review_params)
        redirect_to admin_reviews_path, notice: "Review was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @review.destroy
      redirect_to admin_reviews_path, notice: "Review was successfully destroyed."
    end

    def toggle_active
      @review = Review.find(params[:id])
      @review.update(active: !@review.active)
      redirect_to admin_reviews_path, notice: "Review is now #{@review.active ? 'visible' : 'hidden'}."
    end

    private

    def set_review
      @review = Review.find(params[:id])
    end

    def review_params
      params.require(:review).permit(:business_id, :client_name, :client_role, :content, :rating, :active)
    end
  end
end
