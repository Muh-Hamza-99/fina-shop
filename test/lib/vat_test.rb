require "test_helper"

class VatTest < ActiveSupport::TestCase
  test "is 15 percent of the taxable amount" do
    assert_equal 1_500, Vat.amount(10_000)
    assert_equal 0, Vat.amount(0)
  end

  test "rounds half up to the nearest halala" do
    assert_equal 0, Vat.amount(1)    # 0.15
    assert_equal 0, Vat.amount(3)    # 0.45
    assert_equal 1, Vat.amount(4)    # 0.60
    assert_equal 2, Vat.amount(10)   # 1.50
    assert_equal 7, Vat.amount(49)   # 7.35
    assert_equal 8, Vat.amount(50)   # 7.50
    assert_equal 50, Vat.amount(333) # 49.95
  end

  test "handles large wholesale totals without overflow" do
    assert_equal 1_500_000_000_000, Vat.amount(10_000_000_000_000)
  end

  test "rejects negative and non-integer amounts" do
    assert_raises(ArgumentError) { Vat.amount(-1) }
    assert_raises(ArgumentError) { Vat.amount(10.5) }
    assert_raises(ArgumentError) { Vat.amount("100") }
  end
end
