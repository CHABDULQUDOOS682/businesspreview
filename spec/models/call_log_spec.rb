# frozen_string_literal: true

require "rails_helper"

RSpec.describe CallLog, type: :model do
  it "belongs to optional user and business" do
    call_log = create(:call_log)
    expect(call_log.user).to be_present
    expect(call_log.business).to be_present
  end

  it "formats duration" do
    expect(build(:call_log, duration_seconds: 125).duration_label).to eq("2:05")
    expect(build(:call_log, duration_seconds: 0).duration_label).to eq("-")
  end

  it "returns employee display name" do
    user = create(:user, email: "sam@example.com", name: "Sam")
    expect(build(:call_log, user: user).employee_name).to eq("Sam")
    expect(build(:call_log, user: nil).employee_name).to eq("Unknown employee")
  end
end
