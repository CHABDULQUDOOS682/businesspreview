# frozen_string_literal: true

require "rails_helper"

RSpec.describe Contracts::PdfGenerator do
  let(:admin) { create(:user, :admin) }
  let(:business) { create(:business, email: "client@example.com") }
  let(:contract) { create(:contract, :signed, business: business, created_by: admin) }

  it "renders and attaches a PDF document" do
    pdf = described_class.new(contract).attach!

    expect(pdf).to start_with("%PDF")
    expect(contract.document).to be_attached
    expect(contract.document.content_type).to eq("application/pdf")
  end

  it "embeds a client signature when attached" do
    contract.client_signature.attach(
      io: StringIO.new("\x89PNG\r\n\x1a\n" + ("\x00" * 20)),
      filename: "signature.png",
      content_type: "image/png"
    )

    expect { described_class.new(contract).attach! }.not_to raise_error
    expect(contract.document).to be_attached
  end

  it "renders unsigned contracts without signature section data" do
    draft = create(:contract, business: business, created_by: admin)
    pdf = described_class.new(draft).render
    expect(pdf).to start_with("%PDF")
  end
end
