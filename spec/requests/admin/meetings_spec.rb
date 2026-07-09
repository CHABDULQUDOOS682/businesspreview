require "rails_helper"

RSpec.describe "Admin::Meetings", type: :request do
  let(:employee) { create(:user, role: "employee") }
  let(:other_employee) { create(:user, role: "employee") }
  let(:admin) { create(:user, :admin) }
  let(:business) { create(:business) }
  let!(:my_meeting) do
    create(
      :meeting,
      user: employee,
      business: business,
      client_name: "My Client",
      title: "My client call",
      google_event_id: "evt_my"
    )
  end
  let!(:other_meeting) do
    create(
      :meeting,
      user: other_employee,
      business: create(:business, name: "Other Co"),
      title: "Other call",
      starts_at: 3.days.from_now.change(hour: 15)
    )
  end
  let(:manager) { instance_double(MeetingManager) }

  before do
    allow(MeetingManager).to receive(:new).and_return(manager)
    allow(manager).to receive(:create!).and_return(my_meeting)
    allow(manager).to receive(:update!).and_return(my_meeting)
    allow(manager).to receive(:cancel!).and_return(my_meeting)
  end

  describe "GET /admin/meetings" do
    it "shows only the employee's meetings" do
      sign_in employee
      get admin_meetings_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("My Client")
      expect(response.body).not_to include("Other call")
    end

    it "shows all meetings for admins" do
      sign_in admin
      get admin_meetings_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("My Client")
      expect(response.body).to include("Other Co")
    end
  end

  describe "POST /admin/meetings" do
    it "creates a meeting through the manager" do
      sign_in employee

      expect(manager).to receive(:create!).and_return(my_meeting)
      post admin_meetings_path, params: {
        meeting: {
          business_id: business.id,
          client_name: "Jane",
          client_email: "jane@example.com",
          client_phone: "+1234567890",
          title: "Kickoff",
          description: "Intro",
          meeting_date: 2.days.from_now.to_date,
          meeting_time: "11:00",
          duration_minutes: 30
        }
      }

      expect(response).to redirect_to(admin_meetings_path(month: 2.days.from_now.strftime("%Y-%m"), date: 2.days.from_now.to_date))
      expect(flash[:notice]).to include("Meeting scheduled")
    end
  end

  describe "PATCH /admin/meetings/:id/cancel" do
    it "prevents employees from cancelling another employee's meeting" do
      sign_in employee
      patch cancel_admin_meeting_path(other_meeting)

      expect(response).to redirect_to(admin_meetings_path)
      expect(flash[:alert]).to include("do not have access")
    end

    it "cancels the employee's own meeting" do
      sign_in employee
      expect(manager).to receive(:cancel!).and_return(my_meeting)

      patch cancel_admin_meeting_path(my_meeting)

      expect(response).to redirect_to(admin_meetings_path(month: my_meeting.starts_at.strftime("%Y-%m"), date: my_meeting.starts_at.to_date))
      expect(flash[:notice]).to include("cancelled")
    end
  end

  describe "GET /admin/meetings/new" do
    it "prefills business details when business_id is provided" do
      sign_in employee
      get new_admin_meeting_path(business_id: business.id)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(business.name)
      expect(response.body).to include(business.email)
    end
  end

  describe "PATCH /admin/meetings/:id" do
    it "updates a meeting through the manager" do
      sign_in employee
      expect(manager).to receive(:update!).and_return(my_meeting)

      patch admin_meeting_path(my_meeting), params: {
        meeting: {
          business_id: business.id,
          client_name: "Jane",
          client_email: "jane@example.com",
          client_phone: "+1234567890",
          title: "Updated",
          description: "Updated notes",
          meeting_date: 2.days.from_now.to_date,
          meeting_time: "12:00",
          duration_minutes: 45
        }
      }

      expect(response).to redirect_to(admin_meetings_path(month: 2.days.from_now.strftime("%Y-%m"), date: 2.days.from_now.to_date))
    end
  end
end
