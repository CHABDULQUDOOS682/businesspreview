require "rails_helper"

RSpec.describe "Rack::Attack throttling", type: :request do
  # The test environment uses a null store, which would make every counter reset
  # immediately, so give Rack::Attack somewhere real to count.
  around do |example|
    original_store = Rack::Attack.cache.store
    original_enabled = Rack::Attack.enabled
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.enabled = true
    Rack::Attack.reset!

    example.run
  ensure
    Rack::Attack.reset!
    Rack::Attack.cache.store = original_store
    Rack::Attack.enabled = original_enabled
  end

  before do
    allow(ContactMailer).to receive(:new_lead_alert)
      .and_return(instance_double(ActionMailer::MessageDelivery, deliver_later: true))
  end

  def unique_ip
    "10.#{rand(1..254)}.#{rand(1..254)}.#{rand(1..254)}"
  end

  def submit_contact(ip:)
    post contact_submissions_path,
         params: { first_name: "Jane", email: "jane@example.com", message: "Hi" },
         headers: { "REMOTE_ADDR" => ip }
  end

  it "allows submissions up to the limit" do
    ip = unique_ip
    5.times { submit_contact(ip: ip) }

    expect(response).to have_http_status(:redirect)
  end

  it "throttles the sixth contact submission from one IP" do
    ip = unique_ip
    6.times { submit_contact(ip: ip) }

    expect(response).to have_http_status(:too_many_requests)
    expect(response.body).to include("Too many requests")
    expect(response.headers["Retry-After"]).to be_present
  end

  it "counts each IP separately" do
    blocked = unique_ip
    6.times { submit_contact(ip: blocked) }
    expect(response).to have_http_status(:too_many_requests)

    submit_contact(ip: unique_ip)
    expect(response).to have_http_status(:redirect)
  end

  it "throttles rapid enumeration of public token URLs" do
    ip = unique_ip
    statuses = Array.new(35) do |i|
      get "/lp/probe#{i}-#{SecureRandom.hex(4)}", headers: { "REMOTE_ADDR" => ip }
      response.status
    end

    expect(statuses.count(429)).to be >= 1
    expect(response).to have_http_status(:too_many_requests)
  end

  it "does not throttle ordinary marketing pages" do
    ip = unique_ip
    40.times { get root_path, headers: { "REMOTE_ADDR" => ip } }

    expect(response).to have_http_status(:success)
  end
end
