class Admin::PreviewLinksController < ApplicationController
  layout "admin"
  def create
    business = Business.find(params[:business_id])

    link = business.preview_links.create!(
      template: params[:template]
    )

    redirect_to admin_business_path(business),
      notice: "Link generated: #{landing_page_url(link.uuid)}"
  end

  def destroy
    link = PreviewLink.find(params[:id])
    business = link.business
    link.destroy

    redirect_to admin_business_path(business)
  end
end
