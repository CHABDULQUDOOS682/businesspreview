class Admin::TemplatesController < ApplicationController
  layout "public"

  def preview
    allowed_templates = %w[classic modern minimalist business_preview]

    if allowed_templates.include?(params[:id])
      @template = params[:id]

      @business = Business.new(
        name: "Sample Business LLC",
        city: "New York",
        country: "USA",
        niche: "Software",
        phone: "(555) 123-4567",
        rating: 4.9,
        website_url: "https://example.com"
      )

      render "templates/#{@template}"
    else
      redirect_to admin_templates_path, alert: "The requested template '#{params[:id]}' is not valid."
    end
  end
end
