require 'rails_helper'

RSpec.describe "Admin::Reviews", type: :request do
  let(:admin) { create(:user, :admin) }
  let!(:review) { create(:review) }

  before do
    sign_in admin
  end

  describe "GET /admin/reviews" do
    it "returns http success" do
      get admin_reviews_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/reviews/new" do
    it "returns http success" do
      get new_admin_review_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/reviews" do
    let(:business) { create(:business) }
    let(:valid_params) do
      {
        review: {
          business_id: business.id,
          client_name: "John Doe",
          client_role: "Manager",
          content: "Great service!",
          rating: 5,
          active: true
        }
      }
    end

    it "creates a new review" do
      expect {
        post admin_reviews_path, params: valid_params
      }.to change(Review, :count).by(1)
      expect(response).to redirect_to(admin_reviews_path)
    end

    it "renders new on failure" do
      post admin_reviews_path, params: { review: { client_name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /admin/reviews/:id/edit" do
    it "returns http success" do
      get edit_admin_review_path(review)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /admin/reviews/:id" do
    it "updates the review" do
      patch admin_review_path(review), params: { review: { client_name: "Updated Name" } }
      expect(review.reload.client_name).to eq("Updated Name")
      expect(response).to redirect_to(admin_reviews_path)
    end

    it "renders edit on failure" do
      patch admin_review_path(review), params: { review: { client_name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /admin/reviews/:id" do
    it "destroys the review" do
      expect {
        delete admin_review_path(review)
      }.to change(Review, :count).by(-1)
      expect(response).to redirect_to(admin_reviews_path)
    end
  end

  describe "PATCH /admin/reviews/:id/toggle_active" do
    it "toggles the active status" do
      expect {
        patch toggle_active_admin_review_path(review)
      }.to change { review.reload.active }.from(false).to(true)
      expect(response).to redirect_to(admin_reviews_path)
    end
  end
end
