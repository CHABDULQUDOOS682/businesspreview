require "rails_helper"

RSpec.describe Admin::SidebarHelper, type: :helper do
  let(:user) { create(:user, role: :admin) }

  before do
    allow(helper).to receive(:current_user).and_return(user)
  end

  describe "#admin_sidebar_partial" do
    it "returns the correct partial for admin" do
      expect(helper.admin_sidebar_partial).to eq("admin/shared/sidebars/admin")
    end

    it "returns employee partial for unknown roles" do
      allow(user).to receive(:role).and_return("unknown")
      expect(helper.admin_sidebar_partial).to eq("admin/shared/sidebars/employee")
    end
  end

  describe "#admin_sidebar_role_badge_classes" do
    it "returns purple for super_admin" do
      expect(helper.admin_sidebar_role_badge_classes("super_admin")).to include("purple")
    end

    it "returns blue for admin" do
      expect(helper.admin_sidebar_role_badge_classes("admin")).to include("blue")
    end

    it "returns green for others" do
      expect(helper.admin_sidebar_role_badge_classes("employee")).to include("green")
    end
  end

  describe "#admin_sidebar_nav_link" do
    it "renders a mobile link" do
      html = helper.admin_sidebar_nav_link("Test", "/path", controller: "admin/dashboards", icon: :dashboard, mobile: true)
      expect(html).to include('nav-item')
    end

    it "renders a desktop link" do
      html = helper.admin_sidebar_nav_link("Test", "/path", controller: "admin/dashboards", icon: :dashboard, mobile: false)
      expect(html).to include('sidebar-item')
    end

    it "adds a badge if present" do
      html = helper.admin_sidebar_nav_link("Test", "/path", controller: "admin/dashboards", icon: :dashboard, badge: "5")
      expect(html).to include('5')
    end

    it "handles active state" do
      allow(helper).to receive(:current_page?).and_return(true)
      html = helper.admin_sidebar_nav_link("Test", "/path", controller: "admin/dashboards", icon: :dashboard)
      expect(html).to include("sidebar-item--current")
    end
  end

  describe "#admin_sidebar_icon" do
    [ :dashboard, :businesses, :communications, :tasks, :users, :reviews ].each do |icon|
      it "returns #{icon} icon" do
        expect(helper.admin_sidebar_icon(icon, classes: "w-5")).to include("<svg")
      end
    end

    it "returns empty string for unknown icon" do
      expect(helper.admin_sidebar_icon(:unknown, classes: "w-5")).to include('viewBox="0 0 24 24"')
    end
  end

  describe "#admin_sidebar_unread_badge" do
    before do
      # Manually define the method on the singleton class of helper
      def helper.unread_message_count; 5; end
    end

    it "renders mobile badge" do
      expect(helper.admin_sidebar_unread_badge(mobile: true)).to include("5")
    end

    it "renders desktop badge" do
      expect(helper.admin_sidebar_unread_badge(mobile: false)).to include('id="unread_messages_badge"')
    end
  end

  describe "accent classes" do
    it "handles unknown accents with defaults" do
      expect(helper.send(:admin_sidebar_current_bg_class, :unknown)).to eq("bg-sand-900")
      expect(helper.send(:admin_sidebar_hover_bg_class, :unknown)).to eq("bg-sand-200")
      expect(helper.send(:admin_sidebar_hover_text_class, :unknown)).to eq("text-sand-900")
    end
  end
end
