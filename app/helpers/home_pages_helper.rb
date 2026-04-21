module HomePagesHelper
  def marketing_navigation_links
    [
      [ "Home", root_path ],
      [ "Services", services_path ],
      [ "About", about_path ],
      [ "Process", process_path ],
      [ "Portfolio", portfolio_path ],
      [ "Pricing", pricing_path ]
    ]
  end

  def marketing_footer_columns
    [
      {
        title: "Company",
        links: [
          [ "About", about_path ],
          [ "Careers", contact_path ],
          [ "Press", contact_path ],
          [ "Partners", contact_path ],
          [ "Blog", portfolio_path ]
        ]
      },
      {
        title: "Services",
        links: [
          [ "Web Development", services_path ],
          [ "Branding", services_path ],
          [ "UI/UX Design", services_path ],
          [ "SEO & Content", services_path ],
          [ "Pricing", pricing_path ]
        ]
      },
      {
        title: "Resources",
        links: [
          [ "Case Studies", portfolio_path ],
          [ "Pricing", pricing_path ],
          [ "Help Center", contact_path ],
          [ "Documentation", contact_path ],
          [ "Brand Kit", contact_path ]
        ]
      },
      {
        title: "Legal",
        links: [
          [ "Privacy Policy", privacy_path ],
          [ "Terms of Service", contact_path ],
          [ "Cookie Policy", contact_path ],
          [ "GDPR", contact_path ],
          [ "Accessibility", contact_path ]
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
