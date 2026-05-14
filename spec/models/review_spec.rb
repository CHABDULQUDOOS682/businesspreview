require 'rails_helper'

RSpec.describe Review, type: :model do
  let(:business) { create(:business) }

  describe "validations" do
    it "is valid with valid attributes" do
      review = build(:review, business: business)
      expect(review).to be_valid
    end

    it "is invalid without a client_name" do
      review = build(:review, client_name: nil)
      expect(review).not_to be_valid
    end

    it "is invalid without content" do
      review = build(:review, content: nil)
      expect(review).not_to be_valid
    end

    it "is invalid with rating outside 1-5" do
      expect(build(:review, rating: 0)).not_to be_valid
      expect(build(:review, rating: 6)).not_to be_valid
    end
  end

  describe "scopes" do
    it "has an active scope" do
      active_review = create(:review, active: true)
      hidden_review = create(:review, active: false)
      
      expect(Review.active).to include(active_review)
      expect(Review.active).not_to include(hidden_review)
    end
  end
end
