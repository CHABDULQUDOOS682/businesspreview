class ReviewsController < ApplicationController
  layout "home"
  skip_before_action :authenticate_user!

  def new
    @business = Business.find_by(review_token: params[:token])
    if @business.nil?
      redirect_to root_path, alert: "Invalid review link."
    else
      @review = @business.reviews.build
    end
  end

  def create
    @business = Business.find_by(review_token: params.dig(:review, :review_token))

    if @business.nil?
      redirect_to root_path, alert: "Invalid review link."
      return
    end

    @review = @business.reviews.build(review_params)
    @review.active = false # Require approval by default

    if @review.save
      redirect_to root_path, notice: "Thank you for your review! It will be visible after approval."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def review_params
    params.require(:review).permit(:client_name, :client_role, :content, :rating)
  end
end
