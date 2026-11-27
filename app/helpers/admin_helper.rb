module AdminHelper
  # Sidebar link, highlighted when the current controller is that section.
  def admin_nav_link(label, path, section:)
    active = controller_name == section
    link_to label, path,
      class: [ "block whitespace-nowrap rounded-xl px-3.5 py-3 font-medium", active ? "bg-lime text-ink" : "text-navy-text hover:bg-white/5 hover:text-white" ],
      aria: { current: ("page" if active) }
  end

  def delete_category_confirmation(category)
    [ t("admin.categories.delete_confirm", name: category.name),
      (t("admin.categories.delete_children_warning", count: category.children.size) if category.children.any?) ].compact.join("\n")
  end
end
