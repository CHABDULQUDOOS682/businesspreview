class Admin::TemplatesController < ApplicationController
  layout "public"

  def preview
    allowed_templates = [
      "barber/barber_black_gold",
      "barber/barber_idea",
      "barber/barber_modern",
      "barber/barber_premium",
      "barber/dark_neon",
      "barber/modern_storefront",
      "barber/russell_supply",
      "others/corporate_pro",
      "others/minimalist_elegance",
      "others/vibrant_creative"
    ]

    template_path = params[:id]

    if allowed_templates.include?(template_path)
      @template = template_path

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
      redirect_to admin_root_path,
                  alert: "The requested template '#{template_path}' is not valid."
    end
  end
end