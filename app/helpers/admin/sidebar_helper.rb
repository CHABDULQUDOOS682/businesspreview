module Admin::SidebarHelper
  NAV_ACCENTS = {
    dashboard: :indigo,
    businesses: :orange,
    communications: :green,
    tasks: :blue,
    users: :purple,
    reviews: :indigo,
    commissions: :amber,
    commission_rates: :amber,
    invoices: :green,
    call_logs: :orange,
    preview_links: :indigo,
    notes: :indigo
  }.freeze

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
      "bg-accent-purple-bg text-accent-purple ring-sand-200"
    when "admin"
      "bg-accent-blue-bg text-accent-blue ring-sand-200"
    else
      "bg-accent-green-bg text-accent-green ring-sand-200"
    end
  end

  def admin_sidebar_nav_link(label, path, controller:, icon:, mobile: false, badge: nil)
    active = admin_sidebar_link_active?(path: path, controller: controller)
    accent = admin_sidebar_accent(icon)
    icon_classes = mobile ? "h-5 w-5" : "h-[1.05rem] w-[1.05rem]"

    if mobile
      wrapper_classes = [
        "nav-item justify-between",
        (active ? "#{admin_sidebar_current_bg_class(accent)} active" : nil)
      ].compact.join(" ")

      icon_container_classes = [
        "sidebar-item-icon",
        active ? "text-white" : "bg-sand-100 text-sand-500"
      ].join(" ")

      label_classes = [
        "sidebar-item-label",
        active ? "text-white" : "text-sand-700"
      ].join(" ")

      return link_to path, class: wrapper_classes do
        safe_join(
          [
            content_tag(:span, class: "flex min-w-0 items-center gap-3") do
              safe_join(
                [
                  content_tag(:span, admin_sidebar_icon(icon, classes: icon_classes), class: icon_container_classes),
                  content_tag(:span, label, class: label_classes)
                ]
              )
            end,
            badge.presence
          ].compact
        )
      end
    end

    wrapper_classes = [
      "sidebar-item",
      (active ? "sidebar-item--current #{admin_sidebar_current_bg_class(accent)}" : nil)
    ].compact.join(" ")

    link_to path,
            class: wrapper_classes,
            data: active ? {} : { accent_bg: admin_sidebar_hover_bg_class(accent), accent_text: admin_sidebar_hover_text_class(accent) } do
      safe_join(
        [
          content_tag(
            :span,
            admin_sidebar_icon(icon, classes: icon_classes),
            class: [
              "sidebar-item-icon",
              active ? "text-white" : "text-sand-500"
            ].join(" ")
          ),
          content_tag(:span, label, class: "sidebar-item-label"),
          badge.present? ? content_tag(:span, badge, class: "sidebar-item-badge") : nil
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
      when :reviews
        '<path d="M11 5H6a2 2 0 0 0-2 2v11a2 2 0 0 0 2 2h11a2 2 0 0 0 2-2v-5m-1.414-9.414a2 2 0 1 1 2.828 2.828L11.828 15H9v-2.828l8.586-8.586Z" stroke-linecap="round" stroke-linejoin="round" />'
      when :commissions
        '<path d="M12 6v12m3-9.5H10.5a2.5 2.5 0 0 0 0 5H13.5a2.5 2.5 0 0 1 0 5H9" stroke-linecap="round" stroke-linejoin="round" /><path d="M4 4h16v16H4z" stroke-linecap="round" stroke-linejoin="round" />'
      when :commission_rates
        '<path d="M12 2v20m5-16H9.5a3.5 3.5 0 0 0 0 7H14.5a3.5 3.5 0 0 1 0 7H6" stroke-linecap="round" stroke-linejoin="round" />'
      when :invoices
        '<path d="M9 12h6m-6 4h6m2 5H7a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5.586a1 1 0 0 1 .707.293l5.414 5.414a1 1 0 0 1 .293.707V19a2 2 0 0 1-2 2Z" stroke-linecap="round" stroke-linejoin="round" />'
      when :call_logs
        '<path d="M2 3h6.5l2 5-2.5 1.5a11 11 0 0 0 5 5L14.5 12l5 2V20a2 2 0 0 1-2 2A17 17 0 0 1 2 5a2 2 0 0 1 2-2h-2Z" stroke-linecap="round" stroke-linejoin="round" />'
      when :preview_links
        '<path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71" stroke-linecap="round" stroke-linejoin="round" /><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71" stroke-linecap="round" stroke-linejoin="round" />'
      when :notes
        '<path d="M9 5H7a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2h-2M9 5a2 2 0 0 0 2 2h2a2 2 0 0 0 2-2M9 5a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2m-6 9h4m-4 4h6" stroke-linecap="round" stroke-linejoin="round" />'
      else
        ""
      end

    <<~HTML.html_safe
      <svg class="#{classes}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        #{path}
      </svg>
    HTML
  end

  private

  def admin_sidebar_accent(icon)
    NAV_ACCENTS.fetch(icon.to_sym, :sand)
  end

  def admin_sidebar_current_bg_class(accent)
    case accent
    when :indigo then "bg-accent-indigo"
    when :orange then "bg-accent-orange"
    when :green then "bg-accent-green"
    when :blue then "bg-accent-blue"
    when :purple then "bg-accent-purple"
    when :amber then "bg-accent-amber"
    else "bg-sand-900"
    end
  end

  def admin_sidebar_hover_bg_class(accent)
    case accent
    when :indigo then "bg-accent-indigo-bg"
    when :orange then "bg-accent-orange-bg"
    when :green then "bg-accent-green-bg"
    when :blue then "bg-accent-blue-bg"
    when :purple then "bg-accent-purple-bg"
    when :amber then "bg-accent-amber-bg"
    else "bg-sand-200"
    end
  end

  def admin_sidebar_hover_text_class(accent)
    case accent
    when :indigo then "text-accent-indigo"
    when :orange then "text-accent-orange"
    when :green then "text-accent-green"
    when :blue then "text-accent-blue"
    when :purple then "text-accent-purple"
    when :amber then "text-accent-amber"
    else "text-sand-900"
    end
  end
end
