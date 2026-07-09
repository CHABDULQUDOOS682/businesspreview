# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feedback, type: :model do
  let(:user) { create(:user, role: "employee") }

  it "is valid with default attributes" do
    expect(build(:feedback, user: user)).to be_valid
  end

  it "requires title, description, and feedback_type" do
    feedback = build(:feedback, user: user, title: "", description: "", feedback_type: nil)
    expect(feedback).not_to be_valid
    expect(feedback.errors[:title]).to be_present
    expect(feedback.errors[:description]).to be_present
  end

  it "requires bug fields when feedback_type is bug" do
    feedback = build(:feedback, user: user, feedback_type: "bug", steps_to_reproduce: "", expected_result: "", actual_result: "")
    expect(feedback).not_to be_valid
    expect(feedback.errors[:steps_to_reproduce]).to be_present
    expect(feedback.errors[:expected_result]).to be_present
    expect(feedback.errors[:actual_result]).to be_present
  end

  describe "#editable_by?" do
    it "allows employees to edit their pending feedback" do
      feedback = build(:feedback, user: user, status: "pending")
      expect(feedback.editable_by?(user)).to be(true)
    end

    it "prevents employees from editing after pending" do
      feedback = build(:feedback, user: user, status: "under_review")
      expect(feedback.editable_by?(user)).to be(false)
    end

    it "allows admins to edit any feedback" do
      feedback = build(:feedback, user: user, status: "in_progress")
      expect(feedback.editable_by?(create(:user, :admin))).to be(true)
    end
  end
end
