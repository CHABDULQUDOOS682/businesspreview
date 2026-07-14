require "rails_helper"

RSpec.describe ColdCallingScript, type: :model do
  it "requires title and body" do
    script = build(:cold_calling_script, title: nil, body: nil)
    expect(script).not_to be_valid
    expect(script.errors[:title]).to be_present
    expect(script.errors[:body]).to be_present
  end

  it "filters by category without breaking the relation when blank" do
    create(:cold_calling_script, category: "Opening")
    create(:cold_calling_script, category: "Closing")

    expect(ColdCallingScript.by_category(nil).count).to eq(2)
    expect(ColdCallingScript.by_category("Opening").count).to eq(1)
  end

  it "exposes only active scripts through the active scope" do
    create(:cold_calling_script, active: true)
    create(:cold_calling_script, active: false)

    expect(ColdCallingScript.active.count).to eq(1)
  end
end
