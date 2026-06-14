class Admin::PreviewLinksController < ApplicationController
  layout "admin"

  def index
    @templates = PreviewLink.available_templates
    @businesses = Business.order(:name)

    scope = PreviewLink.includes(:business).order(created_at: :desc)
    scope = scope.where(template: params[:template]) if params[:template].present?
    scope = scope.where(business_id: params[:business_id]) if params[:business_id].present?
    if params[:q].present?
      q = "%#{params[:q]}%"
      scope = scope.joins(:business).where(
        "businesses.name ILIKE :q OR businesses.email ILIKE :q OR preview_links.uuid ILIKE :q",
        q: q
      )
    end

    @pagy, @preview_links = pagy(scope, limit: 25)
    @total_count = PreviewLink.count
    @total_visits = PreviewLink.sum(:visit_count)
    @clicked_count = PreviewLink.where("visit_count > 0").count
  end

  def create
    if params[:business_id].blank? || params[:template].blank?
      redirect_to admin_preview_links_path, alert: "Please select a business and template."
      return
    end

    business = Business.find(params[:business_id])
    link = business.preview_links.create!(template: params[:template])

    redirect_to admin_preview_links_path,
      notice: "Prototype link created for #{business.name}: #{landing_page_url(link.uuid)}"
  rescue ActiveRecord::RecordInvalid => e
    redirect_to admin_preview_links_path(business_id: params[:business_id]),
      alert: e.record.errors.full_messages.to_sentence
  end

  def destroy
    link = PreviewLink.find(params[:id])
    link.destroy

    redirect_to admin_preview_links_path, notice: "Prototype link deleted."
  end
end
