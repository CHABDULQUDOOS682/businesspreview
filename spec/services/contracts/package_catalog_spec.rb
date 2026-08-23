# frozen_string_literal: true

require "rails_helper"

RSpec.describe Contracts::PackageCatalog do
  let(:business) { build(:business, sold_price: 199, subscription_fee: 50) }

  it "suggests subscription and project packages from business fees" do
    expect(described_class.suggest_subscription_key(business)).to eq("growth")
    expect(described_class.suggest_project_key(business)).to eq("starter")
    expect(described_class.suggest_subscription_key(build(:business, subscription_fee: 30))).to eq("essential")
    expect(described_class.suggest_subscription_key(build(:business, subscription_fee: 99))).to eq("business_pro")
    expect(described_class.suggest_project_key(build(:business, sold_price: 299))).to eq("business_growth")
    expect(described_class.suggest_project_key(build(:business, sold_price: 1999))).to eq("custom")
  end

  it "builds subscription payload using business fees" do
    payload = described_class.subscription_payload("growth", business: business)

    expect(payload[:kind]).to eq("subscription")
    expect(payload[:package_key]).to eq("growth")
    expect(payload[:scope_of_work]).to include("Package: Growth")
    expect(payload[:pricing_terms]).to include("One-time setup fee")
    expect(payload[:pricing_terms]).to include("Monthly subscription fee")
    expect(payload[:amount_dollars]).to eq(50.0)
  end

  it "builds project payload and custom quote package" do
    starter = described_class.project_payload("starter", business: business)
    expect(starter[:kind]).to eq("one_time_project")
    expect(starter[:scope_of_work]).to include("Starter Website")
    expect(starter[:amount_dollars]).to eq(199.0)

    custom = described_class.project_payload("custom", business: build(:business, sold_price: nil))
    expect(custom[:pricing_terms]).to include("Custom quote")
    expect(custom[:amount_dollars]).to be_nil
  end

  it "exposes option labels and package labels" do
    expect(described_class.subscription_options.first.last).to eq("essential")
    expect(described_class.project_options.first.last).to eq("starter")
    expect(described_class.package_label("subscription", "growth")).to eq("Growth")
    expect(described_class.package_label("one_time_project", "starter")).to eq("Starter Website")
    expect(described_class.payload_for("subscription", "essential", business: business)[:package_key]).to eq("essential")
  end
end
