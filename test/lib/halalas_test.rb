require "test_helper"

class HalalasTest < ActiveSupport::TestCase
  test "formats arabic with the unit after the amount" do
    assert_equal "1,234.50 ⃁", Halalas.format(123_450, locale: :ar)
  end

  test "formats english with the unit before the amount" do
    assert_equal "⃁ 1,234.50", Halalas.format(123_450, locale: :en)
  end

  test "formats small, zero and negative amounts" do
    assert_equal "⃁ 0.01", Halalas.format(1, locale: :en)
    assert_equal "⃁ 0.00", Halalas.format(0, locale: :en)
    assert_equal "-⃁ 5.00", Halalas.format(-500, locale: :en)
    assert_equal "-5.00 ⃁", Halalas.format(-500, locale: :ar)
  end

  test "formats in the current locale by default" do
    I18n.with_locale(:en) { assert_equal "⃁ 10.00", Halalas.format(1_000) }
  end

  test "parses SAR strings into halalas" do
    assert_equal 123_450, Halalas.from_sar("1,234.5")
    assert_equal 123_450, Halalas.from_sar("1234.50")
    assert_equal 100, Halalas.from_sar("1")
    assert_equal 1, Halalas.from_sar("0.01")
    assert_equal 1_000, Halalas.from_sar(" 10 ")
    assert_equal 500, Halalas.from_sar(5)
  end

  test "parses arabic-indic digits and separators" do
    assert_equal 12_350, Halalas.from_sar("١٢٣٫٥٠")
    assert_equal 123_400, Halalas.from_sar("١٬٢٣٤")
    assert_equal 1_500, Halalas.from_sar("۱۵")
  end

  test "rejects invalid amounts" do
    [ "", "abc", "1.234", "1.2.3", "⃁ 5", nil, 1.5 ].each do |value|
      assert_raises(ArgumentError, "expected #{value.inspect} to be rejected") { Halalas.from_sar(value) }
    end
  end

  test "round-trips through formatting" do
    assert_equal 9_876_543, Halalas.from_sar(Halalas.format(9_876_543, locale: :en).delete_prefix("⃁ "))
  end
end
