class PopulateBlogPostBodiesForServiceNiche < ActiveRecord::Migration[8.0]
  BODIES = {
    "how-to-optimize-your-service-homepage-for-mobile-visitors" => <<~HTML,
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
    "the-3-step-follow-up-sequence-that-prevents-lead-leakage" => <<~HTML,
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
    "connecting-stripe-invoices-directly-to-your-client-booking-flow" => <<~HTML
      <p>Chasing deposits and milestone payments slows delivery. Connecting Stripe invoices to your booking and project handoff keeps cash flow and client communication in sync.</p>
      <h2>Invoice at decision points</h2>
      <p>Send a deposit invoice when the project is approved, then milestone invoices as work ships. Clients pay from a secure Stripe link—no paper checks or awkward reminders.</p>
      <h2>Tie payment to next steps</h2>
      <p>After payment clears, unlock the next deliverable: kickoff call, design round, or go-live checklist. Clear payment gates reduce scope confusion and stalled projects.</p>
      <h2>Keep records automatic</h2>
      <p>Stripe receipts and invoice history give both sides an audit trail. Less admin time means more time delivering the website, booking system, or follow-up setup you sold.</p>
    HTML
  }.freeze

  def up
    BODIES.each do |slug, html|
      post = BlogPost.find_by(slug: slug)
      next unless post
      next if post.readable?

      post.update!(body: html)
    end

    BlogPost.where(slug: "a").or(BlogPost.where(title: "a")).find_each do |junk|
      junk.update!(active: false)
    end
  end

  def down
    BODIES.each_key do |slug|
      post = BlogPost.find_by(slug: slug)
      next unless post

      post.update!(body: nil)
    end
  end
end
