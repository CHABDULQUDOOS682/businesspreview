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

    it "filters meetings for admins" do
      sign_in admin
      get admin_meetings_path, params: {
        q: "My Client",
        employee_id: employee.id,
        status: "scheduled",
        business_id: business.id,
        month: my_meeting.starts_at.strftime("%Y-%m"),
        date: my_meeting.starts_at.to_date
      }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("My Client")
    end

    it "falls back safely for invalid calendar params" do
      sign_in admin
      get admin_meetings_path, params: { month: "invalid", date: "invalid" }

      expect(response).to have_http_status(:ok)
      expect(assigns(:calendar_month)).to eq(Date.current.beginning_of_month)
      expect(assigns(:selected_date)).to eq(Date.current)
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
          starts_at: 2.days.from_now.change(hour: 11).iso8601,
          duration_minutes: 30
        }
      }

      expect(response).to redirect_to(admin_meetings_path(month: 2.days.from_now.strftime("%Y-%m"), date: 2.days.from_now.to_date))
      expect(flash[:notice]).to include("Meeting scheduled")
    end

    it "renders the calendar when validation fails" do
      sign_in employee
      allow(manager).to receive(:create!) do |meeting|
        meeting.errors.add(:title, "can't be blank")
        raise ActiveRecord::RecordInvalid.new(meeting)
      end

      post admin_meetings_path, params: {
        meeting: {
          business_id: business.id,
          client_name: "",
          client_email: "",
          title: "",
          starts_at: 2.days.from_now.change(hour: 11).iso8601,
          duration_minutes: 30
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("My Calendar")
    end

    it "redirects with an alert when Google sync fails" do
      sign_in employee
      allow(manager).to receive(:create!).and_raise(MeetingManager::SyncError.new("sync failed"))

      post admin_meetings_path, params: {
        meeting: {
          business_id: business.id,
          client_name: "Jane",
          client_email: "jane@example.com",
          client_phone: "+1234567890",
          title: "Kickoff",
          meeting_date: 2.days.from_now.to_date,
          starts_at: 2.days.from_now.change(hour: 11).iso8601,
          duration_minutes: 30
        }
      }

      expect(response).to redirect_to(admin_meetings_path(date: 2.days.from_now.to_date))
      expect(flash[:alert]).to include("sync failed")
    end
  end

  describe "GET /admin/meetings/slots" do
    let!(:super_admin) { create(:user, :super_admin) }
    let(:slot_date) { Date.new(2026, 7, 22) }

    before do
      AvailabilityRule.create!(
        user: super_admin,
        day_of_week: 3,
        start_minute: 540,
        end_minute: 660
      )
      sign_in employee
    end

    it "returns available company slots for the selected date" do
      get slots_admin_meetings_path, params: { date: slot_date, duration_minutes: 30 }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Available times for")
      expect(response.body).to include("9:00 AM")
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

    it "redirects when the meeting is not cancellable" do
      my_meeting.update!(status: "completed")
      sign_in employee

      patch cancel_admin_meeting_path(my_meeting)

      expect(response).to redirect_to(admin_meetings_path(month: my_meeting.starts_at.strftime("%Y-%m"), date: my_meeting.starts_at.to_date))
      expect(flash[:alert]).to include("Only scheduled meetings can be cancelled")
    end

    it "redirects with an alert when Google cancel fails" do
      sign_in employee
      allow(manager).to receive(:cancel!).and_raise(MeetingManager::SyncError.new("cancel failed"))

      patch cancel_admin_meeting_path(my_meeting)

      expect(response).to redirect_to(admin_meetings_path(month: my_meeting.starts_at.strftime("%Y-%m"), date: my_meeting.starts_at.to_date))
      expect(flash[:alert]).to include("cancel failed")
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

    it "renders edit when validation fails" do
      sign_in employee
      allow(manager).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(my_meeting))

      patch admin_meeting_path(my_meeting), params: {
        meeting: {
          business_id: business.id,
          client_name: "",
          client_email: "jane@example.com",
          title: "",
          meeting_date: 2.days.from_now.to_date,
          meeting_time: "12:00",
          duration_minutes: 45
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "renders edit when Google sync fails" do
      sign_in employee
      allow(manager).to receive(:update!).and_raise(MeetingManager::SyncError.new("update failed"))

      patch admin_meeting_path(my_meeting), params: {
        meeting: {
          business_id: business.id,
          client_name: "Jane",
          client_email: "jane@example.com",
          client_phone: "+1234567890",
          title: "Updated",
          meeting_date: 2.days.from_now.to_date,
          meeting_time: "12:00",
          duration_minutes: 45
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("update failed")
    end
  end

  describe "GET /admin/meetings/:id/edit" do
    it "renders edit for the employee's own meeting" do
      sign_in employee
      get edit_admin_meeting_path(my_meeting)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Edit Meeting")
    end

    it "blocks employees from editing another employee's meeting" do
      sign_in employee
      get edit_admin_meeting_path(other_meeting)

      expect(response).to redirect_to(admin_meetings_path)
      expect(flash[:alert]).to include("do not have access")
    end

    it "blocks employees even when the meeting exists outside their scope" do
      sign_in employee
      allow_any_instance_of(Admin::MeetingsController).to receive(:scoped_meetings).and_return(Meeting.all)

      patch admin_meeting_path(other_meeting), params: {
        meeting: {
          business_id: business.id,
          client_name: "Jane",
          client_email: "jane@example.com",
          client_phone: "+1234567890",
          title: "Blocked",
          meeting_date: 2.days.from_now.to_date,
          meeting_time: "12:00",
          duration_minutes: 45
        }
      }

      expect(response).to redirect_to(admin_meetings_path)
      expect(flash[:alert]).to include("do not have access")
    end
  end

  describe "GET /admin/meetings/slots with invalid date" do
    before { sign_in employee }

    it "falls back to today when date is invalid" do
      get slots_admin_meetings_path, params: { date: "not-a-date", duration_minutes: 30 }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Available times for")
    end
  end
end
