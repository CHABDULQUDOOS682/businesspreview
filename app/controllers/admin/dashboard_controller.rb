class Admin::DashboardController < ApplicationController
  layout "admin"
  def index
    @business_count = Business.count
    @preview_count  = PreviewLink.count
    @total_visits   = PreviewLink.sum(:visit_count)
    @unread_inbound_count = Message.inbound.unread.count

    @templates = PreviewLink.available_templates

    @recent_businesses = Business.order(created_at: :desc).limit(5)
    @recent_clicks = PreviewLink.where("visit_count > 0").order(updated_at: :desc).limit(5)
  end
end
