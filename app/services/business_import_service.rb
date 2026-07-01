require "csv"

class BusinessImportService
  Result = Struct.new(:row_number, :name, :phone, :status, :reason, keyword_init: true)

  def initialize(file_path, imported_by:)
    @file_path = file_path
    @imported_by = imported_by
  end

  def call
    import = BusinessImport.create!(imported_by: @imported_by, filename: File.basename(@file_path))
    seen_phones_in_file = {}

    CSV.foreach(@file_path, headers: true).with_index(1) do |row, row_number|
      name = row["Business Name"]
      raw_phone = row["Phone Number"]
      normalized_phone = normalize(raw_phone)

      if name.blank?
        record_row(import, row_number, name, raw_phone, "failed", "Business name is blank")
        next
      end

      if normalized_phone.blank?
        record_row(import, row_number, name, raw_phone, "failed", "Phone number is blank")
        next
      end

      if seen_phones_in_file[normalized_phone]
        record_row(
          import,
          row_number,
          name,
          raw_phone,
          "duplicate",
          "Duplicate phone number within this file (first seen on row #{seen_phones_in_file[normalized_phone]})"
        )
        next
      end

      if Business.exists?(["lower(phone) = ?", normalized_phone.downcase])
        record_row(import, row_number, name, raw_phone, "duplicate", "Phone number already exists in the database")
        next
      end

      business = Business.new(
        name: name,
        city: row["City"],
        country: row["Country"],
        niche: row["Business Type"],
        phone: normalized_phone,
        rating: row["Rating"]
      )

      if business.save
        seen_phones_in_file[normalized_phone] = row_number
        record_row(import, row_number, name, raw_phone, "created", nil, business_id: business.id)
      else
        record_row(import, row_number, name, raw_phone, "failed", business.errors.full_messages.to_sentence)
      end
    end

    import.update!(completed_at: Time.current)
    import
  end

  private

  def normalize(phone)
    return nil if phone.blank?

    digits = phone.to_s.gsub(/[^\d+]/, "")
    digits.present? ? "+#{digits.delete('+')}" : nil
  end

  def record_row(import, row_number, name, phone, status, reason, business_id: nil)
    import.business_import_rows.create!(
      row_number: row_number,
      business_name: name,
      phone: phone,
      status: status,
      reason: reason,
      business_id: business_id
    )
  end
end
