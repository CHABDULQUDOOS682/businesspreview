module Admin::SidebarHelper
  def admin_sidebar_partial
    role = current_user&.role.to_s
    role = "employee" unless %w[super_admin admin employee].include?(role)

    "admin/shared/sidebars/#{role}"
  end

  def admin_sidebar_link_active?(path: nil, controller: nil)
    current_page_match = path.present? && current_page?(path)
    controller_match = controller.present? && params[:controller] == controller

    current_page_match || controller_match
  end

  def admin_sidebar_role_badge_classes(role = current_user&.role)
    case role.to_s
    when "super_admin"
      "bg-purple-50 text-purple-700 ring-purple-200"
    when "admin"
      "bg-blue-50 text-blue-700 ring-blue-200"
    else
      "bg-emerald-50 text-emerald-700 ring-emerald-200"
    end
  end

  def admin_sidebar_nav_link(label, path, controller:, icon:, mobile: false, badge: nil)
    active = admin_sidebar_link_active?(path: path, controller: controller)
    wrapper_classes =
      if mobile
        [
          "group flex items-center justify-between gap-3 rounded-md px-3 py-2 text-base font-medium",
          active ? "bg-slate-900 text-white" : "text-slate-700 hover:bg-slate-100 hover:text-slate-900"
        ].join(" ")
      else
        [
          "group flex items-center justify-between gap-2 rounded-md px-2.5 py-2 font-medium",
          active ? "bg-slate-900 text-white" : "text-slate-700 hover:bg-slate-100 hover:text-slate-900"
        ].join(" ")
      end

    icon_container_classes =
      [
        mobile ? "inline-flex h-8 w-8 items-center justify-center rounded-md" : "inline-flex h-6 w-6 items-center justify-center rounded-md",
        active ? "bg-white/10 text-white" : "bg-slate-900/5 text-slate-500 group-hover:text-slate-700"
      ].join(" ")

    icon_classes = mobile ? "h-5 w-5" : "h-4 w-4"

    link_to path, class: wrapper_classes do
      safe_join(
        [
          content_tag(:span, class: "flex items-center gap-#{mobile ? 3 : 2}") do
            safe_join(
              [
                content_tag(:span, admin_sidebar_icon(icon, classes: icon_classes), class: icon_container_classes),
                content_tag(:span, label)
              ]
            )
          end,
          badge.presence
        ].compact
      )
    end
  end

  def admin_sidebar_unread_badge(mobile: false)
    if mobile
      render("admin/communications/unread_badge", count: unread_message_count)
    else
      content_tag(:span, id: "unread_messages_badge") do
        render("admin/communications/unread_badge", count: unread_message_count)
      end
    end
  end

  def admin_sidebar_icon(name, classes:)
    path =
      case name.to_sym
      when :dashboard
        '<path d="M3 13h8V3H3v10Zm10 8h8V11h-8v10Z" stroke-linecap="round" stroke-linejoin="round" />'
      when :businesses
        '<path d="M3 21V8l9-5 9 5v13" stroke-linecap="round" stroke-linejoin="round" />'
      when :communications
        '<path d="M4 5h16v10H5.17L4 16.17V5Z" stroke-linecap="round" stroke-linejoin="round" />'
      when :tasks
        '<path d="M9 11l3 3L22 4M4 7h4m-4 4h4m-4 4h4" stroke-linecap="round" stroke-linejoin="round" />'
      when :users
        '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2m19 0v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75M12 7a4 4 0 1 1-8 0 4 4 0 0 1 8 0Z" stroke-linecap="round" stroke-linejoin="round" />'
      else
        ""
      end

    <<~HTML.html_safe
      <svg class="#{classes}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        #{path}
      </svg>
    HTML
  end
end
