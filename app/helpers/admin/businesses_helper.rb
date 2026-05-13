module Admin
  module BusinessesHelper
    def business_payment_status_badge(business)
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
end
