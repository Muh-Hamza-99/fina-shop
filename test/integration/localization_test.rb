require "test_helper"

class LocalizationTest < ActionDispatch::IntegrationTest
  test "defaults to arabic, right-to-left" do
    get root_path
    assert_response :success
    assert_select "html[lang=ar][dir=rtl]"
    assert_select "h1", I18n.t("home.index.title", locale: :ar)
  end

  test "locale param switches to english and is remembered in a cookie" do
    get root_path(locale: "en")
    assert_select "html[lang=en][dir=ltr]"
    assert_equal "en", cookies[:locale]

    get root_path
    assert_select "html[lang=en][dir=ltr]"
  end

  test "locale param overrides the cookie" do
    get root_path(locale: "en")
    get root_path(locale: "ar")
    assert_select "html[lang=ar][dir=rtl]"
  end

  test "falls back to accept-language" do
    get root_path, headers: { "Accept-Language" => "fr-FR,en-US;q=0.8,ar;q=0.5" }
    assert_select "html[lang=en][dir=ltr]"
  end

  test "ignores unsupported locales" do
    get root_path(locale: "fr")
    assert_select "html[lang=ar][dir=rtl]"
    assert_nil cookies[:locale]
  end

  test "locale switcher links to the other language" do
    get root_path
    assert_select "a[href=?][lang=en]", root_path(locale: :en)
  end
end
