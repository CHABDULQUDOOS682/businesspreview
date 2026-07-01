require "rails_helper"
require "tempfile"

RSpec.describe BusinessImportService do
  def csv_upload(rows)
    file = Tempfile.new([ "business_import", ".csv" ])
    file.write("Business Name,City,Country,Business Type,Phone Number,Rating\n")
    rows.each { |row| file.write("#{row}\n") }
    file.close
    file
  end

  let(:imported_by) { create(:user, :admin) }

  it "creates businesses for fresh valid rows" do
    file = csv_upload([
      "Alpha,Chicago,USA,Consulting,18005550199,4.8",
      "Beta,Austin,USA,Retail,+1 (800) 555-0200,4.6"
    ])

    import = described_class.new(file.path, imported_by: imported_by).call

    expect(import.total_rows).to eq(2)
    expect(import.created_count).to eq(2)
    expect(import.duplicate_count).to eq(0)
    expect(import.failed_count).to eq(0)
    expect(Business.pluck(:phone)).to include("+18005550199", "+18005550200")
  ensure
    file&.unlink
  end

  it "reports a row as duplicate when the phone already exists" do
    create(:business, phone: "+18005550199")
    file = csv_upload([ "Alpha,Chicago,USA,Consulting,1 (800) 555-0199,4.8" ])

    import = described_class.new(file.path, imported_by: imported_by).call
    row = import.business_import_rows.first

    expect(import.created_count).to eq(0)
    expect(row.status).to eq("duplicate")
    expect(row.reason).to eq("Phone number already exists in the database")
  ensure
    file&.unlink
  end

  it "reports duplicate phone numbers within the same file" do
    file = csv_upload([
      "Alpha,Chicago,USA,Consulting,18005550199,4.8",
      "Beta,Austin,USA,Retail,+1 (800) 555-0199,4.6"
    ])

    import = described_class.new(file.path, imported_by: imported_by).call
    duplicate_row = import.business_import_rows.order(:row_number).second

    expect(import.created_count).to eq(1)
    expect(import.duplicate_count).to eq(1)
    expect(duplicate_row.status).to eq("duplicate")
    expect(duplicate_row.reason).to eq("Duplicate phone number within this file (first seen on row 1)")
  ensure
    file&.unlink
  end

  it "reports blank business names and phone numbers as failed rows" do
    file = csv_upload([
      ",Chicago,USA,Consulting,18005550199,4.8",
      "Beta,Austin,USA,Retail,,4.6"
    ])

    import = described_class.new(file.path, imported_by: imported_by).call
    rows = import.business_import_rows.order(:row_number)

    expect(import.failed_count).to eq(2)
    expect(rows.first.reason).to eq("Business name is blank")
    expect(rows.second.reason).to eq("Phone number is blank")
  ensure
    file&.unlink
  end

  it "persists correct counts for a mixed import" do
    create(:business, phone: "+18005550200")
    file = csv_upload([
      "Alpha,Chicago,USA,Consulting,18005550199,4.8",
      "Existing,Austin,USA,Retail,18005550200,4.6",
      "In File Duplicate,Austin,USA,Retail,+1 (800) 555-0199,4.6",
      "Missing Phone,Austin,USA,Retail,,4.6"
    ])

    import = described_class.new(file.path, imported_by: imported_by).call

    expect(import.completed_at).to be_present
    expect(import.total_rows).to eq(4)
    expect(import.created_count).to eq(1)
    expect(import.duplicate_count).to eq(2)
    expect(import.failed_count).to eq(1)
  ensure
    file&.unlink
  end
end
