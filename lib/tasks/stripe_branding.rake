namespace :stripe do
  desc "Upload DevDeBizz logo/icon to Stripe account branding (hosted invoices, PDFs, Stripe emails)"
  task sync_branding: :environment do
    result = StripeBrandingSyncService.call!
    puts "Stripe branding updated for account #{result[:account_id]}"
    puts "Logo file: #{result[:logo_file_id]}"
    puts "Icon file: #{result[:icon_file_id]}"
    puts "Public logo URL: #{result[:public_logo_url]}"
    puts "Verify at: https://dashboard.stripe.com/settings/branding"
  rescue StripeBrandingSyncService::Error, Stripe::StripeError => e
    warn "Failed to sync Stripe branding: #{e.message}"
    warn "Fallback: Dashboard → Settings → Branding → upload #{Rails.root.join('public/brand/logo.png')}"
    exit 1
  end
end
