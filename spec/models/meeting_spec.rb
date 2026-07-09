require "rails_helper"

RSpec.describe Meeting, type: :model do
  let(:employee) { create(:user, role: "employee") }
  let(:business) { create(:business) }

  describe "validations" do
    it "is valid with default attributes" do
      meeting = build(:meeting, user: employee, business: business)
      expect(meeting).to be_valid
    end

    it "requires core fields" do
      meeting = build(:meeting, client_name: nil, client_email: nil, title: nil, starts_at: nil)
      expect(meeting).not_to be_valid
    end

    it "rejects meetings in the past" do
      meeting = build(:meeting, starts_at: 1.hour.ago)
      expect(meeting).not_to be_valid
      expect(meeting.errors[:starts_at]).to include("cannot be in the past")
    end

    it "prevents overlapping meetings for the same employee" do
      create(:meeting, user: employee, business: business, starts_at: 2.days.from_now.change(hour: 10), duration_minutes: 60)
      overlap = build(:meeting, user: employee, business: create(:business), starts_at: 2.days.from_now.change(hour: 10, min: 30), duration_minutes: 30)

      expect(overlap).not_to be_valid
      expect(overlap.errors[:starts_at]).to include("conflicts with another meeting for this employee")
    end

    it "prevents overlapping meetings on the company calendar" do
      other_employee = create(:user, role: "employee")
      create(:meeting, user: employee, business: business, starts_at: 2.days.from_now.change(hour: 14), duration_minutes: 60)
      overlap = build(:meeting, user: other_employee, business: create(:business), starts_at: 2.days.from_now.change(hour: 14, min: 30), duration_minutes: 30)

      expect(overlap).not_to be_valid
      expect(overlap.errors[:starts_at]).to include("conflicts with another meeting on the company calendar")
    end
  end

  describe "#attendee_emails" do
    it "includes client, employee, and company email" do
      meeting = build(:meeting, user: employee, client_email: "client@example.com")
      expect(meeting.attendee_emails).to contain_exactly("client@example.com", employee.email.downcase, Meeting.company_email)
    end

    it "uses the company email for admin organizers instead of their app login email" do
      admin = create(:user, :admin, email: "admin@example.com")
      meeting = build(:meeting, user: admin, client_email: "client@example.com")

      expect(meeting.attendee_emails).to contain_exactly("client@example.com", Meeting.company_email)
      expect(meeting.attendee_emails).not_to include("admin@example.com")
    end

    it "uses the company email for super admin organizers instead of their app login email" do
      super_admin = create(:user, :super_admin, email: "super_admin@example.com")
      meeting = build(:meeting, user: super_admin, client_email: "client@example.com")

      expect(meeting.attendee_emails).to contain_exactly("client@example.com", Meeting.company_email)
      expect(meeting.attendee_emails).not_to include("super_admin@example.com")
    end
  end
end
