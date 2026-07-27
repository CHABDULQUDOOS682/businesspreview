class SeedMarketingContent < ActiveRecord::Migration[8.0]
  def up
    return if BlogPost.exists? || PortfolioItem.exists?

    [
      {
        title: "How to Optimize Your Service Homepage for Mobile Visitors",
        category: "Design",
        excerpt: "Most service-business inquiries happen on mobile screens. Learn to organize elements, place booking buttons, and write clear headlines that fit smaller displays.",
        read_time_label: "5 min read",
        published_on: Date.new(2026, 6, 15),
        body: <<~HTML
          <p>Most service-business inquiries start on a phone. If your homepage feels cramped, slow, or unclear on mobile, visitors leave before they book.</p>
          <h2>Lead with one clear action</h2>
          <p>Above the fold, show who you help, what you do, and one primary CTA—Book now, Call, or Request a quote. Avoid competing buttons that split attention.</p>
          <h2>Make services scannable</h2>
          <p>Use short service names, one-line benefits, and thumb-friendly tap targets. Visitors should understand your offer in under ten seconds without pinching or zooming.</p>
          <h2>Keep forms short</h2>
          <p>Ask only for name, phone or email, and a short note. Extra fields kill conversion on small screens. Confirm the submission with a clear next step.</p>
          <h2>Speed and trust still convert</h2>
          <p>Compress images, keep scripts light, and place reviews or credentials near the CTA—not buried in a footer. A fast, trustworthy mobile homepage turns browsers into booked jobs.</p>
        HTML
      },
      {
        title: "The 3-Step Follow-Up Sequence That Prevents Lead Leakage",
        category: "Automation",
        excerpt: "When a potential client fills out a contact form, timing is everything. Here is the exact email and SMS dispatch blueprint that stops leads from going cold.",
        read_time_label: "7 min read",
        published_on: Date.new(2026, 5, 28),
        body: <<~HTML
          <p>A form fill is not a booked job. Without a fast follow-up sequence, warm leads cool off while you finish the day’s appointments.</p>
          <h2>Step 1: Instant confirmation</h2>
          <p>Within minutes, send an email or SMS that confirms you received the request, sets expectations, and offers a direct reply path or booking link.</p>
          <h2>Step 2: Same-day personal touch</h2>
          <p>Follow with a short human message—call or text—referencing their service need. Speed beats polished scripts when someone is comparing providers today.</p>
          <h2>Step 3: Value reminder at 48 hours</h2>
          <p>If they have not booked, send one more note with a useful tip, FAQ answer, or available slot. Then pause so you stay helpful, not pushy.</p>
          <h2>Track the handoff</h2>
          <p>Log every lead in one place so nothing sits in an inbox. The goal is simple: every inquiry gets a timed response until it books, declines, or goes quiet.</p>
        HTML
      },
      {
        title: "Connecting Stripe Invoices Directly to Your Client Booking Flow",
        category: "Integrations",
        excerpt: "Stop chasing checks. Discover how connecting automated billing milestones directly into your client handoff saves hours of admin work weekly.",
        read_time_label: "6 min read",
        published_on: Date.new(2026, 5, 10),
        body: <<~HTML
          <p>Chasing deposits and milestone payments slows delivery. Connecting Stripe invoices to your booking and project handoff keeps cash flow and client communication in sync.</p>
          <h2>Invoice at decision points</h2>
          <p>Send a deposit invoice when the project is approved, then milestone invoices as work ships. Clients pay from a secure Stripe link—no paper checks or awkward reminders.</p>
          <h2>Tie payment to next steps</h2>
          <p>After payment clears, unlock the next deliverable: kickoff call, design round, or go-live checklist. Clear payment gates reduce scope confusion and stalled projects.</p>
          <h2>Keep records automatic</h2>
          <p>Stripe receipts and invoice history give both sides an audit trail. Less admin time means more time delivering the website, booking system, or follow-up setup you sold.</p>
        HTML
      }
    ].each do |attrs|
      BlogPost.create!(attrs.merge(active: true))
    end

    [
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
    ].each do |attrs|
      PortfolioItem.create!(attrs.merge(active: true))
    end
  end

  def down
    BlogPost.delete_all
    PortfolioItem.delete_all
  end
end
