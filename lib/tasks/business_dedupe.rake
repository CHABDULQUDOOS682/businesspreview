namespace :business do
  desc "Find and merge duplicate businesses by normalized phone number, keeping the oldest record"
  task dedupe_phones: :environment do
    normalize = ->(phone) { phone.to_s.gsub(/[^\d+]/, "") }

    groups = Business.all.group_by { |business| normalize.call(business.phone) }
    groups.each do |norm_phone, businesses|
      next if norm_phone.blank? || businesses.size < 2

      businesses.sort_by!(&:created_at)
      survivor = businesses.first
      duplicates = businesses[1..]

      puts "Merging #{duplicates.size} duplicate(s) of phone #{norm_phone} into Business##{survivor.id}"

      ActiveRecord::Base.transaction do
        duplicates.each do |duplicate|
          %i[payment_invoices notes messages reviews preview_links commissions business_commission_rates].each do |assoc|
            duplicate.public_send(assoc).update_all(business_id: survivor.id)
          end

          survivor.assign_attributes(
            duplicate.attributes.slice(
              "owner_name", "city", "country", "business_location", "niche", "email",
              "website_url", "website_name", "rating"
            ).compact.except(*survivor.attributes.compact.keys)
          )
          survivor.save!(validate: false)
          duplicate.destroy!
        end
      end
    end

    puts "Dedupe complete."
  end
end
