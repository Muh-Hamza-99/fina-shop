require "test_helper"

class HostRoutingTest < ActionDispatch::IntegrationTest
  test "apex serves the marketing home page" do
    host! "example.com"
    get "/"
    assert_response :success
    assert_select "h1", I18n.t("home.index.title", locale: :ar)
  end

  test "www is the apex too" do
    host! "www.example.com"
    get "/"
    assert_select "h1", I18n.t("home.index.title", locale: :ar)
  end

  test "app subdomain serves the merchant admin" do
    host! "app.example.com"
    sign_in_as users(:elshohail_owner)
    get "/"
    assert_response :success
    assert_select "h1", I18n.t("admin.dashboards.show.title", locale: :ar)
  end

  test "store subdomain serves that store's storefront" do
    host! "elshohail.example.com"
    get "/"
    assert_response :success
    assert_select "h1", stores(:elshohail).name_ar
  end

  test "custom domain serves its store's storefront" do
    host! "shop.elshohail.sa"
    get "/", params: { locale: "en" }
    assert_response :success
    assert_select "h1", stores(:elshohail).name_en
  end

  test "unknown store subdomain is a 404" do
    host! "missing.example.com"
    get "/"
    assert_response :not_found
  end

  test "unknown custom domain is a 404" do
    host! "unknown-shop.com"
    get "/"
    assert_response :not_found
  end

  test "reserved subdomains do not resolve to a store" do
    host! "api.example.com"
    get "/"
    assert_response :not_found
  end
end
