require "rails_helper"

RSpec.describe Admin::BusinessesHelper, type: :helper do
  describe "#business_payment_status_badge" do
    let(:business) { create(:business, subscription: false, subscription_fee: nil) }

    it "returns 'No invoice' if no invoice exists" do
      expect(helper.business_payment_status_badge(business)).to include("No invoice")
    end

    it "returns a green badge for paid status" do
      create(:payment_invoice, business: business, status: "paid")
      expect(helper.business_payment_status_badge(business)).to include("bg-green-50")
      expect(helper.business_payment_status_badge(business)).to include("Paid")
    end

    it "returns 'Pending' for opened status" do
      create(:payment_invoice, business: business, status: "opened")
      expect(helper.business_payment_status_badge(business)).to include("Pending")
    end

    it "returns badge for invoice_sent status" do
      create(:payment_invoice, business: business, status: "invoice_sent")
      expect(helper.business_payment_status_badge(business)).to include("Invoice Sent")
    end

    it "returns badge for draft status" do
      create(:payment_invoice, business: business, status: "draft")
      expect(helper.business_payment_status_badge(business)).to include("Draft")
    end

    it "returns badge for failed status" do
      create(:payment_invoice, business: business, status: "failed")
      expect(helper.business_payment_status_badge(business)).to include("Failed")
    end

    it "returns default badge for unknown status" do
      create(:payment_invoice, business: business, status: "void")
      expect(helper.business_payment_status_badge(business)).to include("bg-slate-50")
    end

    context "for subscription businesses" do
      let(:business) { create(:business, subscription: true, subscription_fee: 50) }

      it "returns the subscription payment status label" do
        business.update!(subscription_payment_status: "current")

        expect(helper.business_payment_status_badge(business)).to include("Payment Current")
        expect(helper.business_payment_status_badge(business)).to include("bg-emerald-50")
      end

      it "returns inactive when billing has not started" do
        expect(helper.business_payment_status_badge(business)).to include("Inactive")
      end

      it "returns past due status" do
        business.update!(subscription_payment_status: "past_due")

        expect(helper.business_payment_status_badge(business)).to include("Payment Overdue")
        expect(helper.business_payment_status_badge(business)).to include("bg-amber-50")
      end

      it "returns suspended status" do
        business.update!(subscription_payment_status: "suspended")

        expect(helper.business_payment_status_badge(business)).to include("Suspended")
        expect(helper.business_payment_status_badge(business)).to include("bg-red-50")
      end
    end
  end

  describe "#sitepilot_connection_badge" do
    let(:business) do
      create(
        :business,
        business_number: "B000006",
        site_external_id: "slug",
        site_api_base_url: "http://dashboard.lvh.me:3001",
        site_api_secret: "secret"
      )
    end

    it "shows ready when connection fields are present" do
      expect(helper.sitepilot_connection_badge(business)).to include("Connection ready")
    end

    it "shows incomplete when connection fields are missing" do
      business.update!(site_external_id: nil)

      expect(helper.sitepilot_connection_badge(business)).to include("Connection incomplete")
    end
  end

  describe "#sitepilot_website_control_badge" do
    let(:business) do
      create(
        :business,
        business_number: "B000006",
        site_external_id: "slug",
        site_api_base_url: "http://dashboard.lvh.me:3001",
        site_api_secret: "secret"
      )
    end

    it "shows paused when site_deactivated_at is set" do
      business.update!(site_deactivated_at: Time.current)

      expect(helper.sitepilot_website_control_badge(business)).to include("Website paused via CRM")
    end

    it "shows controllable when linked and not paused" do
      expect(helper.sitepilot_website_control_badge(business)).to include("Website controllable")
    end

    it "shows not linked when connection is incomplete" do
      business.update!(site_api_secret: nil)

      expect(helper.sitepilot_website_control_badge(business)).to include("Not linked")
    end
  end

  describe "#business_location_link" do
    let(:business) { create(:business) }

    it "returns a Google Maps link when business location is a URL" do
      business.business_location = "https://www.google.com/maps/place/Acme"

      html = helper.business_location_link(business)

      expect(html).to include("Open location")
      expect(html).to include("https://www.google.com/maps/place/Acme")
      expect(html).to include('target="_blank"')
    end

    it "builds a Google Maps search link when business location is plain text" do
      business.business_location = "Birmingham Alabama"

      html = helper.business_location_link(business)

      expect(html).to include("https://www.google.com/maps/search/?api=1&amp;query=Birmingham%20Alabama")
    end

    it "uses the URL from a markdown-style location link" do
      business.business_location = "[https://maps.example/acme](https://maps.example/acme)"

      html = helper.business_location_link(business)

      expect(html).to include("https://maps.example/acme")
      expect(html).not_to include("%5Bhttps")
    end

    it "returns a dash when business location is blank" do
      business.business_location = nil

      expect(helper.business_location_link(business)).to eq("-")
    end
  end
end
