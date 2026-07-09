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
          content_tag(:span, "No Invoice", class: "text-slate-400 text-xs")
        end
      end
    end

    def business_location_link(business)
      location = business.business_location.presence
      return "-" if location.blank?

      location = location.to_s.match(/\[[^\]]+\]\(([^)]+)\)/)&.captures&.first || location
      href = location.match?(%r{\Ahttps?://}i) ? location : "https://www.google.com/maps/search/?api=1&query=#{ERB::Util.url_encode(location)}"

      link_to "Open location", href, target: "_blank", rel: "noopener", class: "text-blue-600 hover:text-blue-500"
    end
  end
end
