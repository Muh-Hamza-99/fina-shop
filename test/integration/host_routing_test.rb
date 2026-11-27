require "test_helper"

class HostRoutingTest < ActionDispatch::IntegrationTest
  test "apex serves the marketing home page" do
    host! "example.com"
    get "/"
    assert_select "h1", I18n.t("home.index.hero.title", locale: :ar)
  end

  test "app subdomain serves the merchant admin" do
    host! "app.example.com"
    sign_in_as users(:elshohail_owner)
    get "/"
    assert_select "h1", I18n.t("admin.dashboards.show.title", locale: :ar)
  end

  test "store subdomain and custom domain serve that store's storefront" do
    host! "elshohail.example.com"
    get "/"
    assert_select "h1", stores(:elshohail).name_ar

    host! "shop.elshohail.sa"
    get "/"
    assert_select "h1", stores(:elshohail).name_ar
  end

  test "unknown stores are a 404" do
    host! "missing.example.com"
    get "/"
    assert_response :not_found
  end
end
