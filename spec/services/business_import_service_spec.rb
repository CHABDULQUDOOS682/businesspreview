require "rails_helper"
require "tempfile"

RSpec.describe BusinessImportService do
  def csv_upload(rows)
    file = Tempfile.new([ "business_import", ".csv" ])
    file.write("Country,City,Business Location,Business Name,Rating,OutOff,Business Type,Email,Phone Number,Website\n")
    rows.each { |row| file.write("#{row}\n") }
    file.close
    file
  end

  let(:imported_by) { create(:user, :admin) }

  it "creates businesses for fresh valid rows" do
    file = csv_upload([
      "USA,Chicago,[https://maps.example/alpha](https://maps.example/alpha),Alpha,4.8,-10,Consulting,alpha@example.com,18005550199,[https://alpha.example](https://alpha.example)",
      "USA,Austin,https://maps.example/beta,Beta,4.6,-8,Retail,beta@example.com,+1 (800) 555-0200,https://beta.example"
    ])

    import = described_class.new(file.path, imported_by: imported_by).call

    expect(import.total_rows).to eq(2)
    expect(import.created_count).to eq(2)
    expect(import.duplicate_count).to eq(0)
    expect(import.failed_count).to eq(0)
    expect(Business.pluck(:phone)).to include("+18005550199", "+18005550200")
    expect(Business.find_by(phone: "+18005550199")).to have_attributes(
      business_location: "https://maps.example/alpha",
      email: "alpha@example.com",
      website_url: "https://alpha.example"
    )
  ensure
    file&.unlink
  end

  it "reports a row as duplicate when the phone already exists" do
    create(:business, phone: "+18005550199")
    file = csv_upload([ "USA,Chicago,https://maps.example/alpha,Alpha,4.8,-10,Consulting,alpha@example.com,1 (800) 555-0199,https://alpha.example" ])

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
      "USA,Chicago,https://maps.example/alpha,Alpha,4.8,-10,Consulting,alpha@example.com,18005550199,https://alpha.example",
      "USA,Austin,https://maps.example/beta,Beta,4.6,-8,Retail,beta@example.com,+1 (800) 555-0199,https://beta.example"
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

  it "reports rows that fail model validation on save" do
    failing_business = build(:business)
    failing_business.errors.add(:base, "Could not save")
    allow(Business).to receive(:new).and_call_original
    allow(Business).to receive(:new).with(hash_including(name: "Gamma")).and_return(failing_business)
    allow(failing_business).to receive(:save).and_return(false)

    file = csv_upload([
      "USA,Chicago,https://maps.example/gamma,Gamma,4.8,-10,Consulting,gamma@example.com,18005550333,https://gamma.example"
    ])

    import = described_class.new(file.path, imported_by: imported_by).call
    row = import.business_import_rows.first

    expect(import.created_count).to eq(0)
    expect(import.failed_count).to eq(1)
    expect(row.status).to eq("failed")
    expect(row.reason).to eq("Could not save")
  ensure
    file&.unlink
  end

  it "reports blank business names and phone numbers as failed rows" do
    file = csv_upload([
      "USA,Chicago,https://maps.example/blank,,4.8,-10,Consulting,blank@example.com,18005550199,https://blank.example",
      "USA,Austin,https://maps.example/beta,Beta,4.6,-8,Retail,beta@example.com,,https://beta.example"
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
      "USA,Chicago,https://maps.example/alpha,Alpha,4.8,-10,Consulting,alpha@example.com,18005550199,https://alpha.example",
      "USA,Austin,https://maps.example/existing,Existing,4.6,-8,Retail,existing@example.com,18005550200,https://existing.example",
      "USA,Austin,https://maps.example/file-duplicate,In File Duplicate,4.6,-8,Retail,file@example.com,+1 (800) 555-0199,https://file.example",
      "USA,Austin,https://maps.example/missing,Missing Phone,4.6,-8,Retail,missing@example.com,,https://missing.example"
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
