require "test_helper"

class LocalizationTest < ActionDispatch::IntegrationTest
  test "defaults to arabic, right-to-left" do
    get root_path
    assert_select "html[lang=ar][dir=rtl]"
  end

  test "locale param switches language and is remembered in a cookie" do
    get root_path(locale: "en")
    assert_select "html[lang=en][dir=ltr]"

    get root_path
    assert_select "html[lang=en][dir=ltr]"
  end

  test "falls back to accept-language" do
    get root_path, headers: { "Accept-Language" => "fr-FR,en-US;q=0.8" }
    assert_select "html[lang=en][dir=ltr]"
  end

  test "locale links are not prefetched on hover, since visiting them saves the cookie" do
    get root_path
    assert_select "a[lang=en][data-turbo-prefetch=false]"
  end
end
