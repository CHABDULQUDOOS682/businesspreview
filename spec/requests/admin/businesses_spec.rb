require "rails_helper"

RSpec.describe "Admin::Businesses", type: :request do
  # Include ActiveJob matchers to cleanly verify .deliver_later execution
  include ActiveJob::TestHelper

  let(:user) { create(:user) } # Assumes FactoryBot user is present
  let(:business) { create(:business, email: "developer.qudoos@gmail.com") }

  before do
    # If using Devise, sign in your user context here before sending admin requests:
    sign_in user if respond_to?(:sign_in)
  end

  describe "POST /admin/businesses/:id/send_review_link" do
    context "with email delivery method" do
      it "sends an email and redirects" do
        expect {
          post send_review_link_admin_business_path(business), params: { delivery_method: 'email' }
        }.to have_enqueued_mail(ReviewMailer, :send_link).with(business)

        expect(response).to redirect_to(admin_business_path(business))
      end
    end

    context "with sms delivery method" do
      it "sends an SMS and redirects" do
        # Assuming you mock SmsService or have it wired up safely
        allow(SmsService).to receive(:send_sms).and_return(true)
        business.update(phone: "+1234567890")

        post send_review_link_admin_business_path(business), params: { delivery_method: 'sms' }

        expect(response).to redirect_to(admin_business_path(business))
      end
    end
  end
end
