class AddUniqueIndexToBusinessesPhone < ActiveRecord::Migration[8.0]
  class MigrationBusiness < ActiveRecord::Base
    self.table_name = "businesses"

    has_many :payment_invoices, foreign_key: :business_id, dependent: :nullify
    has_many :notes, foreign_key: :business_id, dependent: :nullify
    has_many :messages, foreign_key: :business_id, dependent: :nullify
    has_many :reviews, foreign_key: :business_id, dependent: :nullify
    has_many :preview_links, foreign_key: :business_id, dependent: :nullify
    has_many :commissions, foreign_key: :business_id, dependent: :nullify
    has_many :business_commission_rates, foreign_key: :business_id, dependent: :nullify
  end

  def up
    execute <<~SQL
      UPDATE businesses
      SET phone = regexp_replace(phone, '[^0-9+]', '', 'g')
      WHERE phone IS NOT NULL;
    SQL

    merge_duplicate_businesses_by_phone

    add_index :businesses, "lower(phone)", unique: true, name: "index_businesses_on_lower_phone"
  end

  def down
    remove_index :businesses, name: "index_businesses_on_lower_phone"
  end

  private

  def merge_duplicate_businesses_by_phone
    duplicate_phones = select_values(<<~SQL)
      SELECT lower(phone)
      FROM businesses
      WHERE phone IS NOT NULL AND phone <> ''
      GROUP BY lower(phone)
      HAVING COUNT(*) > 1
    SQL

    duplicate_phones.each do |phone|
      businesses = MigrationBusiness.where("lower(phone) = ?", phone).order(:created_at, :id).to_a
      survivor = businesses.first

      businesses.drop(1).each do |duplicate|
        %i[payment_invoices notes messages reviews preview_links commissions business_commission_rates].each do |assoc|
          duplicate.public_send(assoc).update_all(business_id: survivor.id)
        end

        fill_blank_survivor_fields(survivor, duplicate)
        duplicate.destroy!
      end
    end
  end

  def fill_blank_survivor_fields(survivor, duplicate)
    fields = %w[owner_name city country niche email website_url website_name rating]
    updates = fields.each_with_object({}) do |field, attrs|
      attrs[field] = duplicate.public_send(field) if survivor.public_send(field).blank? && duplicate.public_send(field).present?
    end

    return if updates.empty?

    survivor.update_columns(updates.merge(updated_at: Time.current))
    survivor.assign_attributes(updates)
  end
end
