require "application_system_test_case"

class HostRoutingSystemTest < ApplicationSystemTestCase
  test "apex, admin and storefront are served on their own hosts" do
    visit root_path(locale: :en)
    assert_selector "h1", text: I18n.t("home.index.title", locale: :en)

    visit_host Hosts.admin_host, "/?locale=en"
    assert_selector "h1", text: I18n.t("admin.dashboards.show.title", locale: :en)

    visit_host Hosts.store_host(stores(:elshohail)), "/?locale=en"
    assert_selector "h1", text: stores(:elshohail).name_en
  end
end
