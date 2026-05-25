require "rails_helper"

RSpec.describe PaymentInvoiceMailer, type: :mailer do
  let(:business) { create(:business, email: "client@example.com") }
  let(:payment_invoice) { create(:payment_invoice, business: business) }

  describe "invoice_link" do
    let(:mail) { PaymentInvoiceMailer.with(payment_invoice: payment_invoice).invoice_link }

    it "renders the headers" do
      expect(mail.subject).to include(payment_invoice.kind_label)
      expect(mail.to).to eq([ business.email ])
      expect(mail.from).to eq([ ApplicationMailer.default[:from] ]) # Use the actual default from the mailer
    end

    it "renders the body" do
      expect(mail.body.encoded).to include(payment_invoice.payment_token)
    end
  end

  describe "due_soon_followup" do
    let(:mail) { PaymentInvoiceMailer.with(payment_invoice: payment_invoice).due_soon_followup }

    it "renders the headers" do
      expect(mail.subject).to include("Reminder")
      expect(mail.to).to eq([ business.email ])
    end

    it "renders the body" do
      expect(mail.body.encoded).to include(payment_invoice.payment_token)
    end
  end
end
