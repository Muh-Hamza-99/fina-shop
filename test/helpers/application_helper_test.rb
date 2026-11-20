require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "arabic is right-to-left" do
    assert_equal "rtl", text_direction(:ar)
  end

  test "english is left-to-right" do
    assert_equal "ltr", text_direction(:en)
  end

  test "defaults to the current locale" do
    I18n.with_locale(:en) { assert_equal "ltr", text_direction }
  end
end
