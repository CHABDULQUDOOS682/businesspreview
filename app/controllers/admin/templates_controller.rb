class Admin::TemplatesController < ApplicationController
  layout "public"

  def preview
    @template = params[:id]

    # Use the first business for realistic data, or create a mock one.
    @business = Business.first || Business.new(
      name: "Sample Business LLC",
      city: "New York",
      country: "USA",
      niche: "Software",
      phone: "(555) 123-4567",
      rating: 4.9,
      website: "https://example.com"
    )

    render "templates/#{@template}"
  end
end
