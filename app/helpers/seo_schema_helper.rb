module SeoSchemaHelper
  ORGANIZATION_DESCRIPTION = "DevDeBizz designs mobile-ready websites, SEO pages, booking flows, and follow-up systems for service businesses.".freeze

  SERVICE_OFFERS = [
    { name: "Website Design", path: "/website-design" },
    { name: "SEO Foundations", path: "/seo" },
    { name: "Booking Systems", path: "/booking-systems" },
    { name: "Follow-Up Systems", path: "/follow-up-systems" }
  ].freeze

  BREADCRUMB_LABELS = {
    "services" => "Services",
    "website-design" => "Website Design",
    "seo" => "SEO",
    "booking-systems" => "Booking Systems",
    "follow-up-systems" => "Follow-Up Systems",
    "about" => "About",
    "process" => "Process",
    "pricing" => "Pricing",
    "portfolio" => "Portfolio",
    "contact" => "Contact",
    "blog" => "Blog",
    "careers" => "Careers",
    "press" => "Press",
    "partners" => "Partners",
    "help_center" => "Help Center",
    "documentation" => "Documentation",
    "brand_kit" => "Brand Kit",
    "privacy" => "Privacy",
    "terms" => "Terms",
    "cookie_policy" => "Cookie Policy",
    "gdpr" => "GDPR",
    "accessibility" => "Accessibility",
    "schedule" => "Schedule"
  }.freeze

  def marketing_structured_data_tags
    return "".html_safe unless marketing_schema_layout?

    blocks = [ organization_schema ]
    blocks << local_business_schema if local_business_schema_page?
    blocks << service_catalog_schema if service_schema_page?
    blocks << breadcrumb_schema if breadcrumb_schema_page?
    blocks << article_schema(@blog_post) if article_schema_page?
    blocks << help_center_faq_schema if help_center_schema_page?

    safe_join(blocks.compact.map { |data| json_ld_script_tag(data) }, "\n")
  end

  private

  def marketing_schema_layout?
    controller.is_a?(HomePagesController) || controller.is_a?(SchedulingController)
  end

  def local_business_schema_page?
    (controller_name == "home_pages" && action_name.in?(%w[index contact])) ||
      (controller_name == "scheduling" && action_name == "new")
  end

  def service_schema_page?
    controller_name == "home_pages" && action_name.in?(%w[services website_design seo booking_systems follow_up_systems])
  end

  def breadcrumb_schema_page?
    return false if controller_name == "home_pages" && action_name == "index"

    marketing_schema_layout?
  end

  def article_schema_page?
    controller_name == "home_pages" && action_name == "blog_show" && @blog_post.present?
  end

  def help_center_schema_page?
    controller_name == "home_pages" && action_name == "help_center"
  end

  def schema_site_origin
    host = ENV.fetch("APP_HOST", request.host)
    protocol = ENV.fetch("APP_PROTOCOL") { request.ssl? ? "https" : request.protocol.delete_suffix("://") }
    "#{protocol}://#{host}"
  end

  def schema_logo_url
    "#{schema_site_origin}/brand/logo.png"
  end

  def schema_telephone
    return if contact_phone.blank?

    digits = contact_phone.gsub(/[^\d+]/, "")
    digits.presence
  end

  def organization_schema
    {
      "@context" => "https://schema.org",
      "@type" => "Organization",
      "name" => app_name,
      "url" => schema_site_origin,
      "logo" => schema_logo_url,
      "description" => ORGANIZATION_DESCRIPTION,
      "email" => contact_email,
      "telephone" => schema_telephone
    }.compact
  end

  def local_business_schema
    {
      "@context" => "https://schema.org",
      "@type" => "ProfessionalService",
      "name" => app_name,
      "image" => schema_logo_url,
      "url" => schema_site_origin,
      "telephone" => schema_telephone,
      "email" => contact_email,
      "priceRange" => "$$",
      "address" => {
        "@type" => "PostalAddress",
        "streetAddress" => "1001 S. Main St. STE 500",
        "addressLocality" => "Kalispell",
        "addressRegion" => "MT",
        "postalCode" => "59901",
        "addressCountry" => "US"
      },
      "geo" => {
        "@type" => "GeoCoordinates",
        "latitude" => 48.1888861,
        "longitude" => -114.3098297
      },
      "openingHoursSpecification" => [
        {
          "@type" => "OpeningHoursSpecification",
          "dayOfWeek" => %w[Monday Tuesday Wednesday Thursday Friday],
          "opens" => "09:00",
          "closes" => "17:00"
        }
      ]
    }.compact
  end

  def service_catalog_schema
    offers = SERVICE_OFFERS.map do |offer|
      {
        "@type" => "Offer",
        "itemOffered" => {
          "@type" => "Service",
          "name" => offer[:name],
          "url" => "#{schema_site_origin}#{offer[:path]}"
        }
      }
    end

    {
      "@context" => "https://schema.org",
      "@type" => "Service",
      "serviceType" => "Website design, SEO, booking, and follow-up systems",
      "provider" => {
        "@type" => "Organization",
        "name" => app_name,
        "url" => schema_site_origin
      },
      "areaServed" => "US",
      "hasOfferCatalog" => {
        "@type" => "OfferCatalog",
        "name" => "DevDeBizz Services",
        "itemListElement" => offers
      }
    }
  end

  def breadcrumb_schema
    items = breadcrumb_list_items
    return if items.blank?

    {
      "@context" => "https://schema.org",
      "@type" => "BreadcrumbList",
      "itemListElement" => items.each_with_index.map do |crumb, index|
        {
          "@type" => "ListItem",
          "position" => index + 1,
          "name" => crumb[:name],
          "item" => crumb[:item]
        }
      end
    }
  end

  def breadcrumb_list_items
    crumbs = [ { name: "Home", item: "#{schema_site_origin}/" } ]

    if controller_name == "home_pages" && action_name == "blog_show" && @blog_post.present?
      crumbs << { name: "Blog", item: "#{schema_site_origin}/blog" }
      crumbs << { name: @blog_post.title, item: "#{schema_site_origin}/blog/#{@blog_post.slug}" }
      return crumbs
    end

    if controller_name == "scheduling"
      crumbs << { name: "Schedule", item: "#{schema_site_origin}/schedule" }
      return crumbs
    end

    path = request.path.delete_prefix("/")
    label = BREADCRUMB_LABELS[path]
    return crumbs if label.blank?

    if path.in?(%w[website-design seo booking-systems follow-up-systems])
      crumbs << { name: "Services", item: "#{schema_site_origin}/services" }
    end

    crumbs << { name: label, item: "#{schema_site_origin}/#{path}" }
    crumbs
  end

  def article_schema(post)
    return if post.blank?

    data = {
      "@context" => "https://schema.org",
      "@type" => "Article",
      "headline" => post.title,
      "description" => post.meta_description.presence || post.excerpt,
      "author" => {
        "@type" => "Organization",
        "name" => app_name
      },
      "publisher" => {
        "@type" => "Organization",
        "name" => app_name,
        "logo" => {
          "@type" => "ImageObject",
          "url" => schema_logo_url
        }
      },
      "datePublished" => (post.published_on || post.created_at.to_date).iso8601,
      "dateModified" => post.updated_at.to_date.iso8601,
      "mainEntityOfPage" => "#{schema_site_origin}/blog/#{post.slug}"
    }

    if post.featured_image.attached?
      data["image"] = rails_blob_url(post.featured_image)
    end

    data
  end

  def help_center_faq_schema
    faqs = [
      {
        question: "How long does a website project take?",
        answer: HomePagesHelper::MARKETING_TIMELINE_SUMMARY
      },
      {
        question: "Do you offer custom designs?",
        answer: "Yes. Every brand wordmark, color scheme, layout structure, and asset is crafted specifically for your target audience."
      },
      {
        question: "What are your payment terms?",
        answer: "Usually, we require a 50% deposit to initiate design, and the remaining 50% upon final sign-off and site launch."
      },
      {
        question: "How do I pay invoices?",
        answer: "We send secure Stripe invoice links via email. You can pay instantly using credit card, Apple Pay, or bank transfers."
      },
      {
        question: "Do you offer hosting support?",
        answer: "Yes, we provide fully-managed staging and deployment support to guarantee maximum performance and SEO speed."
      },
      {
        question: "How do I request edits?",
        answer: "Clients can email us or submit support request messages directly. We usually implement minor modifications within 24 hours."
      }
    ]

    {
      "@context" => "https://schema.org",
      "@type" => "FAQPage",
      "mainEntity" => faqs.map do |faq|
        {
          "@type" => "Question",
          "name" => faq[:question],
          "acceptedAnswer" => {
            "@type" => "Answer",
            "text" => faq[:answer]
          }
        }
      end
    }
  end

  def json_ld_script_tag(data)
    tag.script(
      data.to_json.html_safe,
      type: "application/ld+json"
    )
  end
end
