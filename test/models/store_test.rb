require "test_helper"

class StoreTest < ActiveSupport::TestCase
  def build_store(**attributes)
    Store.new(name_ar: "متجر", subdomain: "new-store", **attributes)
  end

  test "starts a 14 day trial on create" do
    freeze_time do
      store = build_store
      store.save!
      assert store.trialing?
      assert_equal 14.days.from_now, store.trial_ends_at
    end
  end

  test "subdomain must be well formed, unreserved and unique" do
    assert_equal "my-shop", build_store(subdomain: " My-Shop ").subdomain
    assert_not build_store(subdomain: "my_shop").valid?
    assert_not build_store(subdomain: "admin").valid?
    assert_not build_store(subdomain: "ELSHOHAIL").valid?
  end

  test "custom domain cannot be a fina.shop domain" do
    assert build_store(custom_domain: "shop.example.sa").valid?
    assert_not build_store(custom_domain: "other.fina.shop").valid?
  end

  test "normalizes saudi phone numbers to E.164" do
    [ "0501234567", "+966 50 123 4567", "00966501234567" ].each do |input|
      assert_equal "+966501234567", build_store(phone: input).phone, "for #{input}"
    end
    assert_not build_store(phone: "12345").valid?
  end

  test "validates the VAT number format" do
    assert build_store(vat_number: "3000 0000 0000 003").valid?
    assert_not build_store(vat_number: "100000000000003").valid?
  end

  test "national address is complete only with all ZATCA fields" do
    assert stores(:elshohail).national_address_complete?
    assert_not stores(:bare).national_address_complete?
  end

  test "finds stores by storefront host" do
    assert_equal stores(:elshohail), Store.find_by_host("Elshohail.example.com")
    assert_equal stores(:elshohail), Store.find_by_host("shop.elshohail.sa")
    assert_nil Store.find_by_host("missing.example.com")
    assert_nil Store.find_by_host("elshohail.other.com")
  end
end
