require "test_helper"

class HalalasTest < ActiveSupport::TestCase
  test "formats amounts per locale" do
    assert_equal "1,234.50 ⃁", Halalas.format(123_450, locale: :ar)
    assert_equal "⃁ 1,234.50", Halalas.format(123_450, locale: :en)
    assert_equal "-⃁ 5.00", Halalas.format(-500, locale: :en)
  end

  test "parses SAR input, including arabic-indic digits" do
    assert_equal 123_450, Halalas.from_sar("1,234.5")
    assert_equal 1, Halalas.from_sar("0.01")
    assert_equal 12_350, Halalas.from_sar("١٢٣٫٥٠")
    assert_equal 500, Halalas.from_sar(5)
  end

  test "rejects invalid amounts and floats" do
    [ "", "abc", "1.234", nil, 1.5 ].each do |value|
      assert_raises(ArgumentError, "expected #{value.inspect} to be rejected") { Halalas.from_sar(value) }
    end
  end
end
