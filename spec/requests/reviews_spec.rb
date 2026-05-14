require 'rails_helper'

RSpec.describe "Reviews", type: :request do
  let!(:business) { create(:business) }

  describe "GET /reviews/new/:token" do
    it "returns http success for valid token" do
      get new_review_submission_path(token: business.review_token)
      expect(response).to have_http_status(:success)
    end

    it "redirects for invalid token" do
      get new_review_submission_path(token: "invalid")
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include("Invalid review link")
    end
  end

  describe "POST /review_submissions" do
    let(:valid_params) do
      {
        review: {
          review_token: business.review_token,
          client_name: "Test User",
          client_role: "Tester",
          content: "Excellent experience.",
          rating: 4
        }
      }
    end

    it "creates a new review and redirects to root" do
      expect {
        post review_submissions_path, params: valid_params
      }.to change(Review, :count).by(1)
      
      review = Review.last
      expect(review.business).to eq(business)
      expect(review.active).to be_falsey
      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to include("Thank you for your review")
    end

    it "renders new if review_token is missing or invalid" do
      post review_submissions_path, params: { review: { client_name: "Test" } }
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include("Invalid review link")
    end

    it "renders new on validation failure" do
      post review_submissions_path, params: { 
        review: { review_token: business.review_token, client_name: "" } 
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "handles missing review parameter" do
      post review_submissions_path, params: { something_else: {} }
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Invalid review link.")
    end
  end
end
