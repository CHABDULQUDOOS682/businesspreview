module ApplicationHelper
  include Pagy::Frontend

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
