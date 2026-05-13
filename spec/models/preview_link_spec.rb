require "rails_helper"

RSpec.describe PreviewLink, type: :model do
  let(:business) { create(:business) }

  describe "callbacks" do
    it "generates a uuid before creation" do
      link = PreviewLink.new(business: business, template: "barber/barber_modern")
      link.valid?
      expect(link.uuid).to be_present
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
