module ApplicationHelper
  include Pagy::Frontend

  APP_NAME = "DevDeBizz".freeze
  DEFAULT_META_DESCRIPTION = "DevDeBizz builds mobile-ready websites, client-friendly funnels, SEO foundations, and follow-up systems for service businesses that want more qualified leads.".freeze

  def app_name
    APP_NAME
  end

  def default_meta_description
    DEFAULT_META_DESCRIPTION
  end

  def seo_meta_tags
    title = content_for(:title).presence || app_name
    description = content_for(:meta_description).presence || default_meta_description
    image = content_for(:og_image).presence || image_url("veloqtech_logo.svg")
    canonical = content_for(:canonical_url).presence || request.original_url

    safe_join(
      [
        tag.meta(name: "description", content: description),
        tag.link(rel: "canonical", href: canonical),
        tag.meta(property: "og:site_name", content: app_name),
        tag.meta(property: "og:title", content: title),
        tag.meta(property: "og:description", content: description),
        tag.meta(property: "og:type", content: "website"),
        tag.meta(property: "og:url", content: canonical),
        tag.meta(property: "og:image", content: image),
        tag.meta(name: "twitter:card", content: "summary_large_image"),
        tag.meta(name: "twitter:title", content: title),
        tag.meta(name: "twitter:description", content: description),
        tag.meta(name: "theme-color", content: "#213885")
      ],
      "\n"
    )
  end

  def nav_link_to(name, path)
    classes = if current_page?(path)
      "rounded-full bg-slate-900 px-4 py-2 text-sm font-semibold text-white"
    else
      "rounded-full px-4 py-2 text-sm font-semibold text-slate-600 transition hover:bg-white/80 hover:text-slate-950"
    end

    link_to name, path, class: classes
  end

  def visible_business_segment_tabs(tabs)
    tabs = Array(tabs)
    return tabs unless employee_role?

    tabs.select { |tab| tab[:key].to_s == "nurture" }
  end
end
