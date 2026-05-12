require "rails_helper"

RSpec.describe Admin::SidebarHelper, type: :helper do
  let(:user) { create(:user, role: "admin") }

  before do
    allow(helper).to receive(:current_user).and_return(user)
  end

  describe "#admin_sidebar_partial" do
    it "returns blue classes for admin" do
      expect(helper.admin_sidebar_role_badge_classes("admin")).to include("text-accent-blue")
    end

    it "returns employee for unknown roles" do
      allow(helper).to receive(:current_user).and_return(double("user", role: "unknown"))
      expect(helper.admin_sidebar_partial).to eq("admin/shared/sidebars/employee")
    end
  end

  describe "#admin_sidebar_link_active?" do
    before do
      allow(helper).to receive(:current_page?).and_return(false)
      allow(helper).to receive(:params).and_return({ controller: "admin/businesses" })
    end

    it "returns true if controller matches" do
      expect(helper.admin_sidebar_link_active?(controller: "admin/businesses")).to be true
    end

    it "returns false if neither match" do
      expect(helper.admin_sidebar_link_active?(path: "/other", controller: "other")).to be false
    end
  end

  describe "#admin_sidebar_role_badge_classes" do
    it "returns blue classes for admin" do
      expect(helper.admin_sidebar_role_badge_classes("admin")).to include("text-accent-blue")
    end

    it "returns purple classes for super_admin" do
      expect(helper.admin_sidebar_role_badge_classes("super_admin")).to include("text-accent-purple")
    end
  end

  describe "#admin_sidebar_nav_link" do
    before do
      allow(helper).to receive(:admin_sidebar_link_active?).and_return(false)
    end

    it "renders a mobile sidebar link" do
      result = helper.admin_sidebar_nav_link("Businesses", "/admin/businesses", controller: "admin/businesses", icon: :businesses, mobile: true)
      expect(result).to include("nav-item")
    end

    it "renders an active mobile sidebar link" do
      allow(helper).to receive(:admin_sidebar_link_active?).and_return(true)
      result = helper.admin_sidebar_nav_link("Businesses", "/admin/businesses", controller: "admin/businesses", icon: :businesses, mobile: true)
      expect(result).to include("active")
    end
  end

  describe "#admin_sidebar_unread_badge" do
    before do
      helper.define_singleton_method(:unread_message_count) { 5 }
    end

    it "renders desktop badge" do
      expect(helper.admin_sidebar_unread_badge).to include("unread_messages_badge")
    end

    it "renders mobile badge" do
      expect(helper.admin_sidebar_unread_badge(mobile: true)).not_to include("unread_messages_badge")
    end
  end

  describe "icon and accent fallbacks" do
    it "handles unknown icons" do
      expect(helper.admin_sidebar_icon(:unknown, classes: "w-5")).to include("svg")
    end

    it "handles unknown accents" do
      accent = helper.send(:admin_sidebar_accent, :unknown)
      expect(helper.send(:admin_sidebar_current_bg_class, accent)).to eq("bg-sand-900")
      expect(helper.send(:admin_sidebar_hover_bg_class, accent)).to eq("bg-sand-200")
      expect(helper.send(:admin_sidebar_hover_text_class, accent)).to eq("text-sand-900")
    end
  end
end
