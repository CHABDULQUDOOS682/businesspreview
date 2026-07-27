# frozen_string_literal: true

class RefreshPortfolioItemsForServiceNiche < ActiveRecord::Migration[8.0]
  NICHE_ITEMS = [
    {
      title: "Barbershop Website Redesign: More Chair Bookings",
      category: "Barbershop",
      description: "Mobile-first site with clear services, gallery, hours, and a direct path to book — built for walk-ins deciding on their phone.",
      metric: "+ Booking requests",
      accent_color: "from-[#213885]/30",
      position: 1
    },
    {
      title: "Salon Multi-Page Site: Staff, Services & SEO",
      category: "Salon",
      description: "Five-page salon presence with staff and service pages, gallery management, and SEO foundations so clients can find and book faster.",
      metric: "5-page build",
      accent_color: "from-emerald-400/30",
      position: 2
    },
    {
      title: "Clinic Website Redesign: + Appointment Inquiries",
      category: "Clinic",
      description: "Patient-friendly service pages, reviews placement, and a contact flow designed to turn research visits into booked appointments.",
      metric: "Appointment-ready",
      accent_color: "from-cyan-400/30",
      position: 3
    },
    {
      title: "Consultant Site: Clear Packages, Qualified Leads",
      category: "Consulting",
      description: "Offer-first layout that explains packages quickly, builds trust, and routes serious inquiries into a simple booking or call path.",
      metric: "Lead capture",
      accent_color: "from-amber-300/30",
      position: 4
    },
    {
      title: "Home Services Website: Service-Area Pages That Convert",
      category: "Home services",
      description: "Service-area pages, project gallery, and mobile contact flows for homeowners comparing crews after a search.",
      metric: "Search visibility",
      accent_color: "from-rose-400/30",
      position: 5
    },
    {
      title: "Studio & Spa Site: Seasonal Offers, Steady Updates",
      category: "Salon",
      description: "Brand-forward site with gallery management, business hours, and a monthly update rhythm for seasonal promotions.",
      metric: "Managed hosting",
      accent_color: "from-violet-400/30",
      position: 6
    }
  ].freeze

  LEGACY_TITLES = [
    "Neighborhood Barbershop",
    "Growth Salon",
    "Local Clinic",
    "Service Consultant",
    "Home Services Crew",
    "Studio & Spa",
    "Norvik Apparel",
    "PulseMetric",
    "Kavari Pay",
    "MediLoop",
    "Orbit Studios"
  ].freeze

  def up
    say_with_time "Refreshing portfolio items for service-business niche" do
      PortfolioItem.where(title: LEGACY_TITLES).update_all(active: false, updated_at: Time.current)
      PortfolioItem.where("char_length(title) < 3 OR char_length(category) < 2")
                   .update_all(active: false, updated_at: Time.current)

      NICHE_ITEMS.each do |attrs|
        item = PortfolioItem.where(position: attrs[:position], title: LEGACY_TITLES).order(:id).first ||
               PortfolioItem.find_by(title: attrs[:title]) ||
               PortfolioItem.new

        item.assign_attributes(attrs.merge(active: true))
        item.save!
      end
    end
  end

  def down
    # Irreversible content refresh.
  end
end
