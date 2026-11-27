module AdminHelper
  # Sidebar link, highlighted when the current controller is that section.
  def admin_nav_link(label, path, section:)
    active = controller_name == section
    link_to label, path,
      class: [ "block whitespace-nowrap rounded-md px-3 py-2", active ? "bg-gray-900 text-white" : "text-gray-700 hover:bg-gray-100" ],
      aria: { current: ("page" if active) }
  end

  def delete_category_confirmation(category)
    [ t("admin.categories.delete_confirm", name: category.name),
      (t("admin.categories.delete_children_warning", count: category.children.size) if category.children.any?) ].compact.join("\n")
  end
end
