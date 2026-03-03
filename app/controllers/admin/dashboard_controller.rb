class Admin::DashboardController < ApplicationController
  layout "admin"
  def index
    @business_count = Business.count
    @preview_count  = PreviewLink.count
    @total_visits   = PreviewLink.sum(:visit_count)

    @templates = PreviewLink.available_templates

    @recent_businesses = Business.order(created_at: :desc).limit(5)
    @recent_clicks = PreviewLink.where.not(clicked_at: nil)
                                .order(clicked_at: :desc)
                                .limit(5)
  end
end
