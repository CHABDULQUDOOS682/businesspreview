module HomePagesHelper
  # Single timeline framing used on Home, Process, Pricing, and Help Center.
  MARKETING_TIMELINE_SUMMARY = <<~TEXT.squish.freeze
    We start planning in the first week. A focused starter site often launches in about
    2–3 days after scope is locked; fuller multi-page builds usually take 4–6 days.
    Custom booking systems and portals are scoped separately according to app size.
  TEXT

  MARKETING_TIMELINE_SHORT = <<~TEXT.squish.freeze
    Week-one planning · Starter ~2–3 days · Growth builds ~4–6 days · Custom apps according to app size
  TEXT

  def marketing_timeline_summary
    MARKETING_TIMELINE_SUMMARY
  end

  def marketing_timeline_short
    MARKETING_TIMELINE_SHORT
  end

  def marketing_navigation_links
    [
      [ "Home", root_path ],
      [ "Services", services_path ],
      [ "About", about_path ],
      [ "Process", process_path ],
      [ "Portfolio", portfolio_path ],
      [ "Pricing", pricing_path ],
      [ "Blog", blog_path ]
    ]
  end

  def marketing_footer_columns
    [
      {
        title: "Company",
        links: [
          [ "About", about_path ],
          [ "Careers", careers_path ],
          [ "Press", press_path ],
          [ "Partners", partners_path ],
          [ "Blog", blog_path ]
        ]
      },
      {
        title: "Services",
        links: [
          [ "Website design", website_design_path ],
          [ "SEO foundations", seo_path ],
          [ "Booking systems", booking_systems_path ],
          [ "Follow-up systems", follow_up_systems_path ]
        ]
      },
      {
        title: "Resources",
        links: [
          # [ "Case Studies", portfolio_path ],
          [ "Pricing", pricing_path ],
          [ "Help Center", help_center_path ],
          [ "Documentation", documentation_path ],
          [ "Brand Kit", brand_kit_path ]
        ]
      },
      {
        title: "Legal",
        links: [
          [ "Privacy Policy", privacy_path ],
          [ "Terms of Service", terms_path ],
          [ "Cookie Policy", cookie_policy_path ],
          [ "GDPR", gdpr_path ],
          [ "Accessibility", accessibility_path ]
        ]
      }
    ]
  end

  def marketing_nav_link_classes(path)
    base = "relative rounded-full px-4 py-2 text-sm font-semibold transition"

    if current_page?(path)
      "#{base} bg-[#213885]/10 text-[#5F3475] ring-1 ring-[#213885]/25"
    else
      "#{base} text-[#081849]/70 hover:bg-[#081849]/5 hover:text-[#081849]"
    end
  end
end
