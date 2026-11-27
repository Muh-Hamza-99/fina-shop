require "application_system_test_case"

class LocaleSwitchingTest < ApplicationSystemTestCase
  test "switching between arabic and english flips text direction" do
    visit root_path(locale: :ar)
    assert_selector "html[dir=rtl]"
    assert_selector "h1", text: I18n.t("home.index.hero.title", locale: :ar)

    click_on "English"
    assert_selector "html[dir=ltr]"
    assert_selector "h1", text: I18n.t("home.index.hero.title", locale: :en)

    click_on "العربية"
    assert_selector "html[dir=rtl]"
  end
end
