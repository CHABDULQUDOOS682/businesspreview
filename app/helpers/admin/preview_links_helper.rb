module Admin::PreviewLinksHelper
  def preview_link_template_label(template)
    template.to_s.titleize
  end

  def preview_link_public_url(preview_link)
    landing_page_url(preview_link.uuid)
  end
end
