require "rails_helper"

RSpec.describe Commission, type: :model do
  describe "validations" do
    it "is valid with proper attributes" do
      commission = build(:commission)
      expect(commission).to be_valid
    end

    it "requires status to be in STATUSES" do
      commission = build(:commission, status: "invalid")
      expect(commission).not_to be_valid
    end

    it "calculates commission_amount on validation" do
      commission = build(:commission, base_amount: 1000.0, percentage: 10.0, commission_amount: nil)
      expect(commission).to be_valid
      expect(commission.commission_amount).to eq(100.0)
    end

    it "requires month_number when subscription" do
      commission = build(:commission, kind: "subscription", month_number: nil)
      expect(commission).not_to be_valid
    end

    it "must not have month_number when one_time" do
      commission = build(:commission, kind: "one_time", month_number: 1)
      expect(commission).not_to be_valid
    end

    it "allows only one commission per invoice and month" do
      existing = create(:commission, kind: "one_time", month_number: nil)
      duplicate = build(:commission, payment_invoice: existing.payment_invoice, kind: "one_time", month_number: nil)

      expect(duplicate).not_to be_valid
    end
  end

  describe "scopes" do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    before do
      create(:commission, user: user1, status: "pending")
      create(:commission, user: user2, status: "approved")
    end

    it "filters by employee" do
      expect(described_class.for_employee(user1).count).to eq(1)
    end

    it "filters by pending" do
      expect(described_class.pending.count).to eq(1)
    end
  end

  describe "#approve!" do
    let(:approving_user) { create(:user, :admin) }
    let(:employee) { create(:user) }
    let(:commission) { create(:commission, user: employee, percentage: 10.0, base_amount: 100.0) }

    it "approves the commission and sets auditor details" do
      commission.approve!(approving_user)
      expect(commission.status).to eq("approved")
      expect(commission.approved_at).to be_present
      expect(commission.approved_by).to eq(approving_user)
    end

    it "applies percentage override and upserts employee rate" do
      expect {
        commission.approve!(approving_user, percentage_override: 15.0)
      }.to change(EmployeeCommissionRate, :count).by(1)

      expect(commission.percentage).to eq(15.0)
      expect(commission.commission_amount).to eq(15.0)

      emp_rate = EmployeeCommissionRate.last
      expect(emp_rate.user).to eq(employee)
      expect(emp_rate.percentage).to eq(15.0)
    end

    it "does not approve a commission that is not pending" do
      commission.update!(status: "approved", approved_at: Time.current, approved_by: approving_user)

      expect { commission.approve!(approving_user) }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "#mark_paid_out!" do
    let(:commission) { create(:commission, status: "approved") }

    it "marks commission as paid_out and records timestamp" do
      commission.mark_paid_out!
      expect(commission.status).to eq("paid_out")
      expect(commission.paid_out_at).to be_present
    end

    it "does not pay out a commission before approval" do
      commission.update!(status: "pending")

      expect { commission.mark_paid_out! }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe ".build_for_paid_invoice!" do
    let(:employee) { create(:user, role: "employee") }
    let(:business) { create(:business, sold_by: employee) }

    before do
      # Global default seed
      create(:commission_rate, kind: "one_time", month_number: nil, percentage: 10.0)
      create(:commission_rate, kind: "subscription", month_number: 1, percentage: 8.0)
      create(:commission_rate, kind: "subscription", month_number: 2, percentage: 4.0)
      create(:commission_rate, kind: "subscription", month_number: 3, percentage: 2.0)
    end

    context "when business has no sold_by attributed user" do
      let(:unattributed_business) { create(:business, sold_by: nil) }
      let(:invoice) { create(:payment_invoice, business: unattributed_business, kind: "one_time", amount_cents: 50000) }

      it "logs warning and returns nil without crashing" do
        expect(Rails.logger).to receive(:warn).with(/has no sold_by/)
        result = described_class.build_for_paid_invoice!(invoice)
        expect(result).to be_nil
      end
    end

    context "when invoice is one_time" do
      let(:invoice) { create(:payment_invoice, business: business, kind: "one_time", amount_cents: 50000, status: "draft") }

      it "creates a pending commission with correct resolved rate" do
        invoice.update!(status: "paid", paid_at: Time.current) # trigger callback

        commission = described_class.find_by(payment_invoice: invoice)
        expect(commission).to be_present
        expect(commission.kind).to eq("one_time")
        expect(commission.month_number).to be_nil
        expect(commission.base_amount).to eq(500.0)
        expect(commission.percentage).to eq(10.0)
        expect(commission.commission_amount).to eq(50.0)
        expect(commission.status).to eq("pending")
      end

      it "prevents duplicate creation on multiple webhook fires (idempotency)" do
        # Manually invoke build twice
        invoice.update!(status: "paid", paid_at: Time.current)
        expect {
          described_class.build_for_paid_invoice!(invoice)
        }.not_to change(described_class, :count)
      end
    end

    context "when invoice is subscription" do
      let(:invoice1) { create(:payment_invoice, business: business, kind: "subscription", amount_cents: 10000, status: "draft") }
      let(:invoice2) { create(:payment_invoice, business: business, kind: "subscription", amount_cents: 10000, status: "draft") }
      let(:invoice3) { create(:payment_invoice, business: business, kind: "subscription", amount_cents: 10000, status: "draft") }
      let(:invoice4) { create(:payment_invoice, business: business, kind: "subscription", amount_cents: 10000, status: "draft") }

      it "determines correct month number and applies tiered global default percentages" do
        # 1st subscription invoice paid
        invoice1.update!(status: "paid", paid_at: Time.current - 3.days)
        comm1 = described_class.find_by(payment_invoice: invoice1)
        expect(comm1.month_number).to eq(1)
        expect(comm1.percentage).to eq(8.0)
        expect(comm1.commission_amount).to eq(8.0)

        # 2nd subscription invoice paid
        invoice2.update!(status: "paid", paid_at: Time.current - 2.days)
        comm2 = described_class.find_by(payment_invoice: invoice2)
        expect(comm2.month_number).to eq(2)
        expect(comm2.percentage).to eq(4.0)

        # 3rd subscription invoice paid
        invoice3.update!(status: "paid", paid_at: Time.current - 1.day)
        comm3 = described_class.find_by(payment_invoice: invoice3)
        expect(comm3.month_number).to eq(3)
        expect(comm3.percentage).to eq(2.0)

        # 4th subscription invoice paid -> should not get a commission
        expect {
          invoice4.update!(status: "paid", paid_at: Time.current)
        }.not_to change(described_class, :count)
      end
    end

    context "percentage override resolution hierarchy" do
      let(:invoice) { create(:payment_invoice, business: business, kind: "one_time", amount_cents: 10000, status: "draft") }

      it "resolves: Business Override > Employee Default > Global Default" do
        # Tier 3 Global Default: 10%
        # Tier 2 Employee Default: 12%
        # Tier 1 Business Override: 15%

        # Scenario A: Just global default
        invoice.update!(status: "paid", paid_at: Time.current)
        comm = described_class.find_by(payment_invoice: invoice)
        expect(comm.percentage).to eq(10.0)

        # Cleanup
        comm.destroy
        invoice.update_columns(status: "draft")

        # Scenario B: Add Employee default override
        create(:employee_commission_rate, user: employee, kind: "one_time", percentage: 12.0)
        invoice.update!(status: "paid", paid_at: Time.current)
        comm = described_class.find_by(payment_invoice: invoice)
        expect(comm.percentage).to eq(12.0)

        # Cleanup
        comm.destroy
        invoice.update_columns(status: "draft")

        # Scenario C: Add Business override
        create(:business_commission_rate, business: business, kind: "one_time", percentage: 15.0)
        invoice.update!(status: "paid", paid_at: Time.current)
        comm = described_class.find_by(payment_invoice: invoice)
        expect(comm.percentage).to eq(15.0)
      end
    end
  end
end
