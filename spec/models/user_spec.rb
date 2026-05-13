require "rails_helper"

RSpec.describe User, type: :model do
  let!(:super_admin) { create(:user, :super_admin) }

  describe "validations" do
    it "prevents creating a second super admin" do
      new_admin = build(:user, role: "super_admin")
      expect(new_admin).not_to be_valid
      expect(new_admin.errors[:role]).to include("can only have one super admin")
    end

    it "allows updating the existing super admin" do
      expect(super_admin).to be_valid
    end

    it "allows non-super-admins" do
      admin = build(:user, :admin)
      expect(admin).to be_valid
    end
  end

  describe "instance methods" do
    it "checks authentication activation" do
      expect(super_admin.active_for_authentication?).to be true
      super_admin.update(active: false)
      expect(super_admin.active_for_authentication?).to be false
    end

    it "returns inactive message" do
      super_admin.update(active: false)
      expect(super_admin.inactive_message).to eq(:inactive)
    end
  end

  describe "#manageable_roles" do
    it "returns admin and employee for super_admin" do
      expect(super_admin.manageable_roles).to contain_exactly("admin", "employee")
    end

    it "returns only employee for admin" do
      admin = create(:user, :admin)
      expect(admin.manageable_roles).to eq(%w[employee])
    end

    it "returns empty array for employee" do
      employee = create(:user)
      expect(employee.manageable_roles).to eq([])
    end
  end

  describe "#can_manage?" do
    let(:admin) { create(:user, :admin) }
    let(:employee) { create(:user) }

    it "returns false for blank user" do
      expect(super_admin.can_manage?(nil)).to be false
    end

    it "returns false when managing self" do
      expect(super_admin.can_manage?(super_admin)).to be false
    end

    it "returns false when target is super_admin" do
      another_super = build(:user, role: "super_admin")
      expect(admin.can_manage?(another_super)).to be false
    end

    it "returns true when role is within manageable_roles" do
      expect(super_admin.can_manage?(employee)).to be true
      expect(admin.can_manage?(employee)).to be true
    end

    it "returns false when role is outside manageable_roles" do
      expect(admin.can_manage?(create(:user, :admin))).to be false
      expect(employee.can_manage?(employee)).to be false
    end
  end
end
