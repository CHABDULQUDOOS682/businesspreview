require "stripe"

# Uploads the DevDeBizz logo to Stripe account branding so hosted invoices,
# invoice PDFs, and Stripe's own invoice emails show the correct mark.
# Stripe File API accepts PNG/JPEG only (not SVG) for business_logo / business_icon.
class StripeBrandingSyncService
  class Error < StandardError; end

  LOGO_PATH = Rails.root.join("public/brand/logo.png")
  FALLBACK_LOGO_PATH = Rails.root.join("app/assets/images/logo/Website Logo PNG.png")
  PUBLIC_LOGO_SVG_PATH = "/brand/logo.svg"

  def self.call!
    new.call!
  end

  def call!
    ensure_configured!
    logo_path = resolve_logo_path!

    logo_file = upload_file!(logo_path, "business_logo")
    icon_file = upload_file!(logo_path, "business_icon")

    account = ::Stripe::Account.retrieve
    ::Stripe::Account.update(
      account.id,
      settings: {
        branding: {
          logo: logo_file.id,
          icon: icon_file.id,
          primary_color: "#213885",
          secondary_color: "#5F3475"
        }
      }
    )

    {
      account_id: account.id,
      logo_file_id: logo_file.id,
      icon_file_id: icon_file.id,
      public_logo_url: public_logo_url
    }
  end

  private

  def ensure_configured!
    raise Error, "STRIPE_SECRET_KEY is not configured" if ::Stripe.api_key.blank?
  end

  def resolve_logo_path!
    path = [ LOGO_PATH, FALLBACK_LOGO_PATH ].find { |candidate| File.exist?(candidate) }
    raise Error, "DevDeBizz logo not found at #{LOGO_PATH}" if path.blank?

    path
  end

  def upload_file!(path, purpose)
    ::Stripe::File.create(
      {
        purpose: purpose,
        file: File.new(path, "rb")
      }
    )
  end

  def public_logo_url
    host = ENV.fetch("APP_HOST", "devdebizz.com")
    protocol = ENV.fetch("APP_PROTOCOL", "https")
    "#{protocol}://#{host}#{PUBLIC_LOGO_SVG_PATH}"
  end
end
