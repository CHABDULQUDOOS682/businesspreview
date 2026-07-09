require "rails_helper"

RSpec.describe GoogleCalendar::RenewWatchJob, type: :job do
  it "registers a watch when no active channel exists" do
    google_calendar = instance_double(GoogleCalendarService, configured?: true)
    allow(GoogleCalendarService).to receive(:new).and_return(google_calendar)
    allow(google_calendar).to receive(:register_webhook!)

    described_class.perform_now

    expect(google_calendar).to have_received(:register_webhook!)
  end

  it "skips registration when an active channel already exists" do
    create(:google_calendar_channel) if GoogleCalendarChannel.table_exists?
    google_calendar = instance_double(GoogleCalendarService, configured?: true)
    allow(GoogleCalendarService).to receive(:new).and_return(google_calendar)
    allow(google_calendar).to receive(:register_webhook!)

    described_class.perform_now

    expect(google_calendar).not_to have_received(:register_webhook!)
  end
end
