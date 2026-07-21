class SeedMarketingContent < ActiveRecord::Migration[8.0]
  def up
    return if BlogPost.exists? || PortfolioItem.exists?

    [
      {
        title: "How to Optimize Your Service Homepage for Mobile Visitors",
        category: "Design",
        excerpt: "Most local service inquiries happen on mobile screens. Learn to organize elements, place booking buttons, and write clear headlines that fit smaller displays.",
        read_time_label: "5 min read",
        published_on: Date.new(2026, 6, 15)
      },
      {
        title: "The 3-Step Follow-Up Sequence That Prevents Lead Leakage",
        category: "Automation",
        excerpt: "When a potential client fills out a contact form, timing is everything. Here is the exact email and SMS dispatch blueprint that stops leads from going cold.",
        read_time_label: "7 min read",
        published_on: Date.new(2026, 5, 28)
      },
      {
        title: "Connecting Stripe Invoices Directly to Your Client Booking Flow",
        category: "Integrations",
        excerpt: "Stop chasing checks. Discover how connecting automated billing milestones directly into your client handoff saves hours of admin work weekly.",
        read_time_label: "6 min read",
        published_on: Date.new(2026, 5, 10)
      }
    ].each do |attrs|
      BlogPost.create!(attrs.merge(active: true))
    end

    [
      { title: "Neighborhood Barbershop", category: "Barbershop", description: "Mobile-first landing site with services, gallery, hours, and a clear path to book a chair.", metric: "Booking-ready", accent_color: "from-[#213885]/30", position: 1 },
      { title: "Growth Salon", category: "Salon", description: "Multi-page salon site with staff and service management, plus SEO foundations for local search.", metric: "5-page site", accent_color: "from-emerald-400/30", position: 2 },
      { title: "Local Clinic", category: "Clinic", description: "Appointment-focused clinic website with reviews, patient-friendly service pages, and follow-up friendly contact flow.", metric: "Appointments", accent_color: "from-cyan-400/30", position: 3 },
      { title: "Service Consultant", category: "Consulting", description: "Offer-first site that clarifies packages, builds trust quickly, and routes qualified leads into a simple booking flow.", metric: "Lead capture", accent_color: "from-amber-300/30", position: 4 },
      { title: "Home Services Crew", category: "Home services", description: "Service-area pages, photo gallery, and contact flows designed for homeowners deciding on mobile.", metric: "Local SEO", accent_color: "from-rose-400/30", position: 5 },
      { title: "Studio & Spa", category: "Salon", description: "Brand-forward site with gallery management, business hours, and ongoing content updates for seasonal offers.", metric: "Managed hosting", accent_color: "from-violet-400/30", position: 6 }
    ].each do |attrs|
      PortfolioItem.create!(attrs.merge(active: true))
    end
  end

  def down
    BlogPost.delete_all
    PortfolioItem.delete_all
  end
end
