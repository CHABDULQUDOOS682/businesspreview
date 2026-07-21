require "rails_helper"

RSpec.describe "Admin::BlogPosts and PortfolioItems coverage extras", type: :model do
  describe PortfolioItem do
    it "auto-assigns position when created at zero" do
      create(:portfolio_item, position: 5)
      item = PortfolioItem.create!(
        title: "Auto Position Build",
        category: "Salon",
        description: "Assigned next position automatically.",
        position: 0,
        active: true
      )

      expect(item.position).to eq(6)
    end

    it "returns initials from the title" do
      item = build(:portfolio_item, title: "Growth Salon")
      expect(item.initials).to eq("GS")
    end
  end
end
