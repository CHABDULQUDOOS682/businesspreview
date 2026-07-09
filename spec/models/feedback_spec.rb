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

    it "allows super admins to edit any feedback" do
      feedback = build(:feedback, user: user, status: "in_progress")
      expect(feedback.editable_by?(create(:user, :super_admin))).to be(true)
    end

    it "returns false when actor is blank" do
      feedback = build(:feedback, user: user)
      expect(feedback.editable_by?(nil)).to be(false)
    end
  end

  describe "#deletable_by?" do
    it "allows only super admins to delete" do
      feedback = build(:feedback, user: user)
      expect(feedback.deletable_by?(create(:user, :super_admin))).to be(true)
      expect(feedback.deletable_by?(create(:user, :admin))).to be(false)
    end
  end

  describe "#manageable_by?" do
    it "allows admins and super admins to manage feedback" do
      feedback = build(:feedback, user: user)
      expect(feedback.manageable_by?(create(:user, :admin))).to be(true)
      expect(feedback.manageable_by?(create(:user, :super_admin))).to be(true)
      expect(feedback.manageable_by?(user)).to be(false)
      expect(feedback.manageable_by?(nil)).to be(false)
    end
  end

  describe "#resolved?" do
    it "returns true for completed or closed feedback" do
      expect(build(:feedback, status: "completed").resolved?).to be(true)
      expect(build(:feedback, status: "closed").resolved?).to be(true)
      expect(build(:feedback, status: "pending").resolved?).to be(false)
    end
  end

  describe "blank submission and screenshots" do
    it "rejects whitespace-only title and description" do
      feedback = build(:feedback, user: user, title: "   ", description: "   ")
      expect(feedback).not_to be_valid
      expect(feedback.errors[:title]).to be_present
      expect(feedback.errors[:description]).to be_present
    end

    it "rejects more than the maximum number of screenshots" do
      feedback = create(:feedback, user: user)
      feedback.screenshots.attach(
        Array.new(Feedback::MAX_SCREENSHOTS + 1) do |index|
          { io: StringIO.new("fake"), filename: "shot#{index}.png", content_type: "image/png" }
        end
      )

      expect(feedback).not_to be_valid
      expect(feedback.errors[:screenshots]).to include("cannot exceed #{Feedback::MAX_SCREENSHOTS} files")
    end

    it "rejects unsupported screenshot content types" do
      feedback = create(:feedback, user: user)
      feedback.screenshots.attach(
        io: StringIO.new("fake"),
        filename: "notes.txt",
        content_type: "text/plain"
      )

      expect(feedback).not_to be_valid
      expect(feedback.errors[:screenshots]).to include("must be PNG, JPG, WEBP, or GIF")
    end
  end
end
