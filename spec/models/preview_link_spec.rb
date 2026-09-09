require "rails_helper"

RSpec.describe PreviewLink, type: :model do
  let(:business) { create(:business) }

  describe "callbacks" do
    it "generates a uuid before creation" do
      link = PreviewLink.new(business: business, template: "barber/barber_modern")
      link.valid?
      expect(link.uuid).to be_present
    end

    it "generates a uuid with enough entropy to resist enumeration" do
      link = create(:preview_link, business: business)

      expect(link.uuid.length).to eq(32)
      expect(link.uuid).to match(/\A[0-9a-f]{32}\z/)
    end

    it "does not reuse uuids" do
      uuids = Array.new(5) { create(:preview_link, business: business).uuid }

      expect(uuids.uniq.size).to eq(5)
    end
  end

  describe "class methods" do
    it "returns available templates" do
      templates = PreviewLink.available_templates
      expect(templates).to include("barber/barber_modern")
    end
  end

  describe "validations" do
    it "validates inclusion of template" do
      link = PreviewLink.new(business: business, template: "invalid")
      expect(link).not_to be_valid
    end
  end
end
