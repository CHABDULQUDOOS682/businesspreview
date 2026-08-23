# frozen_string_literal: true

module Contracts
  class PackageCatalog
    SUBSCRIPTION_PACKAGES = {
      "essential" => {
        name: "Essential",
        title: "Essential partnership agreement",
        monthly_fee: 30,
        setup_fee: 99,
        description: "Best for service businesses that need a professional online presence.",
        website_size: [
          "Landing Page", "Hero Section", "About Section", "Services Section",
          "Gallery/Portfolio Section", "Contact Section", "Location Section"
        ],
        included: [
          "Managed hosting",
          "Security monitoring",
          "Uptime monitoring",
          "Contact form management",
          "2 content updates per month",
          "SEO setup",
          "Mobile responsive design",
          "Email support"
        ],
        not_included: [ "New page creation", "Custom development", "E-commerce" ]
      },
      "growth" => {
        name: "Growth",
        title: "Growth partnership agreement",
        monthly_fee: 50,
        setup_fee: 199,
        description: "Best for businesses actively trying to generate leads.",
        website_size: [ "Up to 5 pages", "Home", "Services", "Gallery/Portfolio", "About", "Contact" ],
        included: [
          "Everything in Essential",
          "Admin dashboard (Overview, Staff, Services, Gallery, Business Hours)",
          "Monthly SEO optimization",
          "Google Analytics setup",
          "Google Search Console",
          "5 content updates per month",
          "Performance monitoring",
          "Priority support",
          "Basic conversion tracking"
        ],
        not_included: []
      },
      "business_pro" => {
        name: "Business Pro",
        title: "Business Pro partnership agreement",
        monthly_fee: 99,
        setup_fee: 299,
        description: "Best for businesses wanting a dedicated web partner.",
        website_size: [
          "Up to 10 pages", "Home", "Services", "Gallery/Portfolio", "About", "Contact",
          "FAQ", "Appointments", "+3 Extra Pages (as needed)"
        ],
        included: [
          "Everything in Growth",
          "Advanced dashboard (Booking, Reviews, Customers)",
          "10 content updates per month",
          "SEO support",
          "Monthly strategy meeting",
          "Priority emergency support",
          "CRM integration support"
        ],
        not_included: []
      }
    }.freeze

    PROJECT_PACKAGES = {
      "starter" => {
        name: "Starter Website",
        title: "Starter website project agreement",
        project_fee: 199,
        description: "Professional website with clear services and a simple contact path.",
        pages: [ "Up to 5 pages", "Home", "About", "Services", "Portfolio/Gallery", "Contact" ],
        included: [
          "Custom UI design",
          "Mobile responsive design",
          "Contact forms",
          "Basic on-page SEO",
          "Google Analytics setup",
          "Speed optimization",
          "SSL configuration",
          "30 days post-launch support"
        ],
        delivery: "2-3 days"
      },
      "business_growth" => {
        name: "Business Growth",
        title: "Business Growth project agreement",
        project_fee: 299,
        description: "More than a brochure site — clearer service pages and stronger lead capture.",
        pages: [ "Up to 12 pages" ],
        included: [
          "Everything in Starter",
          "CMS",
          "Blog setup",
          "Advanced SEO structure",
          "Lead capture forms",
          "Conversion-focused design",
          "60 days priority support"
        ],
        delivery: "4-6 days"
      },
      "custom" => {
        name: "Custom Web Application",
        title: "Custom web application agreement",
        project_fee: nil,
        description: "Custom booking, dashboards, portals, or integrations beyond a standard marketing site.",
        pages: [ "Based on requirements" ],
        included: [
          "Custom Rails web application development",
          "User authentication and roles",
          "Custom admin dashboard",
          "Integrations as scoped",
          "Secure production deployment",
          "Support window as scoped"
        ],
        delivery: "According to app size"
      }
    }.freeze

    def self.suggest_subscription_key(business)
      fee = business.subscription_fee.to_f
      return "essential" if fee.positive? && fee <= 35
      return "growth" if fee.positive? && fee <= 70
      return "business_pro" if fee.positive?

      "growth"
    end

    def self.suggest_project_key(business = nil)
      fee = business&.sold_price.to_f
      return "starter" if fee.positive? && fee <= 220
      return "business_growth" if fee.positive? && fee <= 500
      return "custom" if fee.positive?

      "starter"
    end

    def self.package_label(kind, package_key)
      catalog = kind.to_s == "subscription" ? SUBSCRIPTION_PACKAGES : PROJECT_PACKAGES
      catalog.dig(package_key.to_s, :name) || package_key.to_s.humanize
    end

    def self.project_option_label(key)
      pkg = PROJECT_PACKAGES.fetch(key.to_s)
      if pkg[:project_fee].present?
        "#{pkg[:name]} (#{format_money(pkg[:project_fee])})"
      else
        "#{pkg[:name]} (Custom quote)"
      end
    end

    def self.subscription_option_label(key)
      pkg = SUBSCRIPTION_PACKAGES.fetch(key.to_s)
      "#{pkg[:name]} (#{format_money(pkg[:monthly_fee])}/mo · setup #{format_money(pkg[:setup_fee])})"
    end

    def self.project_options
      PROJECT_PACKAGES.keys.map { |key| [ project_option_label(key), key ] }
    end

    def self.subscription_options
      SUBSCRIPTION_PACKAGES.keys.map { |key| [ subscription_option_label(key), key ] }
    end

    def self.payload_for(kind, package_key, business:)
      if kind == "subscription"
        subscription_payload(package_key, business: business)
      else
        project_payload(package_key, business: business)
      end
    end

    def self.subscription_payload(package_key, business:)
      pkg = SUBSCRIPTION_PACKAGES.fetch(package_key.to_s)
      setup = business.sold_price.presence || pkg[:setup_fee]
      monthly = business.subscription_fee.presence || pkg[:monthly_fee]

      {
        kind: "subscription",
        package_key: package_key.to_s,
        title: pkg[:title],
        amount_dollars: monthly.to_f,
        scope_of_work: subscription_scope(pkg),
        pricing_terms: subscription_pricing(setup: setup, monthly: monthly, package_name: pkg[:name]),
        timeline_terms: "The partnership begins on the effective signature date and renews monthly until cancelled. Setup and launch timing follow the #{pkg[:name]} plan timeline communicated at kickoff.",
        termination_terms: "Either party may terminate with thirty (30) days written notice. Client remains responsible for fees accrued through the end of the notice period. Upon termination, DevDeBizz will provide a reasonable handoff of site files where applicable."
      }
    end

    def self.project_payload(package_key, business:)
      pkg = PROJECT_PACKAGES.fetch(package_key.to_s)
      fee = business.sold_price.presence || pkg[:project_fee]

      {
        kind: "one_time_project",
        package_key: package_key.to_s,
        title: pkg[:title],
        amount_dollars: fee.present? ? fee.to_f : nil,
        scope_of_work: project_scope(pkg),
        pricing_terms: project_pricing(fee: fee, package_name: pkg[:name]),
        timeline_terms: "Delivery target: #{pkg[:delivery]} after scope is locked and required assets/content are received from the client. Delays in client feedback may extend the schedule.",
        termination_terms: "Either party may terminate for material breach after written notice and a reasonable cure period. Client pays for work completed through the termination date. Finished deliverables are released after outstanding invoices are paid."
      }
    end

    def self.js_catalog
      {
        subscription: SUBSCRIPTION_PACKAGES.transform_values { |pkg|
          pkg.slice(:name, :title, :monthly_fee, :setup_fee, :description)
        },
        project: PROJECT_PACKAGES.transform_values { |pkg|
          pkg.slice(:name, :title, :project_fee, :description, :delivery)
        }
      }
    end

    def self.subscription_scope(pkg)
      lines = []
      lines << "Package: #{pkg[:name]}"
      lines << pkg[:description]
      lines << ""
      lines << "Website size:"
      pkg[:website_size].each { |item| lines << "- #{item}" }
      lines << ""
      lines << "Included services:"
      pkg[:included].each { |item| lines << "- #{item}" }
      if pkg[:not_included].present?
        lines << ""
        lines << "Not included:"
        pkg[:not_included].each { |item| lines << "- #{item}" }
      end
      lines.join("\n")
    end

    def self.subscription_pricing(setup:, monthly:, package_name:)
      <<~TEXT.strip
        Package: #{package_name}

        One-time setup fee: #{format_money(setup)}
        Monthly subscription fee: #{format_money(monthly)} / month

        Client pays the one-time setup fee (if any) and the recurring monthly subscription fee stated above. Invoices are due within seven (7) days. Unpaid balances may result in suspension of hosting or related services after notice.
      TEXT
    end

    def self.project_scope(pkg)
      lines = []
      lines << "Package: #{pkg[:name]}"
      lines << pkg[:description]
      lines << ""
      lines << "Pages / scope:"
      pkg[:pages].each { |item| lines << "- #{item}" }
      lines << ""
      lines << "Included:"
      pkg[:included].each { |item| lines << "- #{item}" }
      lines.join("\n")
    end

    def self.project_pricing(fee:, package_name:)
      fee_line = fee.present? ? "Project fee: #{format_money(fee)}" : "Project fee: Custom quote based on features & complexity"

      <<~TEXT.strip
        Package: #{package_name}

        #{fee_line}

        Client pays the project fee stated above according to the invoice schedule. Work may pause if invoices remain unpaid.
      TEXT
    end

    def self.format_money(value)
      number = value.to_f
      ActionController::Base.helpers.number_to_currency(number)
    end
    private_class_method :format_money, :subscription_scope, :subscription_pricing, :project_scope, :project_pricing
  end
end
