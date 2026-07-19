module Admin
  module BusinessesHelper
    def business_payment_status_badge(business)
      if business.subscription_active?
        badge_class = case business.subscription_payment_status
        when "current" then "bg-emerald-50 text-emerald-700 ring-emerald-600/20"
        when "past_due" then "bg-amber-50 text-amber-800 ring-amber-600/20"
        when "suspended" then "bg-red-50 text-red-700 ring-red-600/20"
        else "bg-slate-50 text-slate-600 ring-slate-500/10"
        end

        content_tag(:span, business.subscription_payment_status_label,
                    class: "inline-flex items-center rounded-md px-2 py-1 text-xs font-medium ring-1 ring-inset #{badge_class}")
      else
        invoice = business.payment_invoices.order(created_at: :desc).first

        if invoice.present?
          badge_class = case invoice.status
          when "paid" then "bg-green-50 text-green-700 ring-green-600/20"
          when "invoice_sent" then "bg-blue-50 text-blue-700 ring-blue-600/20"
          when "opened" then "bg-amber-50 text-amber-700 ring-amber-600/20"
          when "draft" then "bg-slate-50 text-slate-600 ring-slate-500/10"
          when "failed" then "bg-red-50 text-red-700 ring-red-600/20"
          else "bg-slate-50 text-slate-600 ring-slate-500/10"
          end

          display_status = invoice.status == "opened" ? "Pending" : invoice.status_label

          content_tag(:span, display_status, class: "inline-flex items-center rounded-md px-2 py-1 text-xs font-medium ring-1 ring-inset #{badge_class}")
        else
          content_tag(:span, "No invoice", class: "inline-flex items-center rounded-md px-2 py-1 text-xs font-medium ring-1 ring-inset bg-slate-50 text-slate-500 ring-slate-500/10")
        end
      end
    end

    def sitepilot_connection_configured?(business)
      business.business_number.present? &&
        business.site_external_id.present? &&
        business.site_api_base_url.present? &&
        business.site_api_secret.present?
    end

    def sitepilot_connection_badge(business)
      if sitepilot_connection_configured?(business)
        content_tag(
          :span,
          "Connection ready",
          class: "inline-flex items-center rounded-md px-2 py-1 text-xs font-medium ring-1 ring-inset bg-emerald-50 text-emerald-700 ring-emerald-600/20"
        )
      else
        content_tag(
          :span,
          "Connection incomplete",
          class: "inline-flex items-center rounded-md px-2 py-1 text-xs font-medium ring-1 ring-inset bg-amber-50 text-amber-800 ring-amber-600/20"
        )
      end
    end

    def sitepilot_website_control_badge(business)
      if business.site_deactivated_at.present?
        content_tag(
          :span,
          "Website paused via CRM",
          class: "inline-flex items-center rounded-md px-2 py-1 text-xs font-medium ring-1 ring-inset bg-red-50 text-red-700 ring-red-600/20",
          title: "site_deactivated_at is set — SitePilot public site should be paused"
        )
      elsif sitepilot_connection_configured?(business)
        content_tag(
          :span,
          "Website controllable",
          class: "inline-flex items-center rounded-md px-2 py-1 text-xs font-medium ring-1 ring-inset bg-slate-50 text-slate-700 ring-slate-500/10",
          title: "CRM can pause/resume the SitePilot public website"
        )
      else
        content_tag(
          :span,
          "Not linked",
          class: "inline-flex items-center rounded-md px-2 py-1 text-xs font-medium ring-1 ring-inset bg-slate-50 text-slate-500 ring-slate-500/10"
        )
      end
    end

    def business_location_link(business)
      location = business.business_location.presence
      return "-" if location.blank?

      location = location.to_s.match(/\[[^\]]+\]\(([^)]+)\)/)&.captures&.first || location
      href = location.match?(%r{\Ahttps?://}i) ? location : "https://www.google.com/maps/search/?api=1&query=#{ERB::Util.url_encode(location)}"

      link_to "Open location", href, target: "_blank", rel: "noopener", class: "text-blue-600 hover:text-blue-500"
    end

    def phone_line_type_badge(business)
      if business.phone_lookup_checked_at.blank?
        return content_tag(:span, "Not checked", class: "text-xs text-slate-400")
      end

      if business.phone_lookup_error.present?
        return content_tag(:span, "Lookup failed",
                           class: "inline-flex items-center rounded-md bg-red-50 px-2 py-0.5 text-xs font-medium text-red-700 ring-1 ring-inset ring-red-600/20")
      end

      badge_class = case business.phone_line_type
      when "mobile" then "bg-emerald-50 text-emerald-700 ring-emerald-600/20"
      when "landline" then "bg-red-50 text-red-700 ring-red-600/20"
      when "fixedVoip", "nonFixedVoip" then "bg-amber-50 text-amber-800 ring-amber-600/20"
      else "bg-slate-50 text-slate-600 ring-slate-500/10"
      end

      content_tag(:span, business.phone_line_type&.titleize || "Unknown",
                  class: "inline-flex items-center rounded-md px-2 py-0.5 text-xs font-medium ring-1 ring-inset #{badge_class}")
    end
  end
end
