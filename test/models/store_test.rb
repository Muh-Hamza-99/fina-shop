require "test_helper"

class StoreTest < ActiveSupport::TestCase
  def build_store(**attributes)
    Store.new(name_ar: "متجر", subdomain: "new-store", **attributes)
  end

  test "fixtures are valid" do
    assert stores(:elshohail).valid?
    assert stores(:bare).valid?
  end

  test "requires an arabic name and a subdomain" do
    store = Store.new
    assert_not store.valid?
    assert store.errors.added?(:name_ar, :blank)
    assert store.errors.added?(:subdomain, :blank)
  end

  test "starts a 14 day trial on create" do
    freeze_time do
      store = build_store
      store.save!
      assert store.trialing?
      assert_equal 14.days.from_now, store.trial_ends_at
    end
  end

  test "does not start a trial for non-trialing stores" do
    store = build_store(subscription_status: "active")
    store.save!
    assert_nil store.trial_ends_at
  end

  test "rejects unknown subscription statuses" do
    assert_not build_store(subscription_status: "free").valid?
  end

  test "normalizes the subdomain to lowercase" do
    assert_equal "my-shop", build_store(subdomain: "  My-Shop ").subdomain
  end

  test "accepts valid subdomains" do
    %w[abc shop-1 a1b 123].each do |subdomain|
      assert build_store(subdomain: subdomain).valid?, "expected #{subdomain} to be valid"
    end
  end

  test "rejects invalid subdomains" do
    [ "ab", "-shop", "shop-", "my_shop", "my.shop", "متجر", "a" * 33 ].each do |subdomain|
      assert_not build_store(subdomain: subdomain).valid?, "expected #{subdomain} to be invalid"
    end
  end

  test "rejects reserved subdomains" do
    %w[www admin app api].each do |subdomain|
      store = build_store(subdomain: subdomain)
      assert_not store.valid?
      assert store.errors.added?(:subdomain, :exclusion, value: subdomain)
    end
  end

  test "subdomain is unique regardless of case" do
    store = build_store(subdomain: "ELSHOHAIL")
    assert_not store.valid?
    assert store.errors.added?(:subdomain, :taken, value: "elshohail")
  end

  test "custom domain is normalized, validated and unique" do
    assert_equal "shop.example.com", build_store(custom_domain: " Shop.Example.COM ").custom_domain
    assert build_store(custom_domain: "shop.example.com").valid?
    assert_not build_store(custom_domain: "not a domain").valid?
    assert_nil build_store(custom_domain: "  ").custom_domain

    stores(:elshohail).update!(custom_domain: "shop.example.com")
    assert_not build_store(custom_domain: "shop.example.com").valid?
  end

  test "custom domain cannot be a fina.shop domain" do
    assert_not build_store(custom_domain: "fina.shop").valid?
    assert_not build_store(custom_domain: "other.fina.shop").valid?
  end

  test "normalizes saudi phone numbers to E.164" do
    [ "0501234567", "+966 50 123 4567", "00966501234567", "966501234567" ].each do |input|
      store = build_store(phone: input, whatsapp_phone: input)
      assert_equal "+966501234567", store.phone, "for #{input}"
      assert_equal "+966501234567", store.whatsapp_phone
      assert store.valid?
    end
  end

  test "rejects invalid phone numbers" do
    store = build_store(phone: "12345")
    assert_not store.valid?
    assert store.errors.added?(:phone, :invalid, value: "12345")
  end

  test "normalizes and validates email" do
    assert_equal "sales@shop.sa", build_store(email: " Sales@Shop.SA ").email
    assert_not build_store(email: "not-an-email").valid?
    assert_nil build_store(email: "").email
  end

  test "adds https to websites without a scheme" do
    assert_equal "https://shop.sa", build_store(website: "shop.sa").website
    assert_equal "http://shop.sa", build_store(website: "http://shop.sa").website
    assert_not build_store(website: "not a site").valid?
  end

  test "validates saudi building number and postal code" do
    assert build_store(building_number: "1234", postal_code: "12211").valid?
    assert_not build_store(building_number: "123").valid?
    assert_not build_store(postal_code: "1221").valid?
  end

  test "skips saudi address formats for other countries" do
    assert build_store(country_code: "ae", building_number: "12", postal_code: "000").valid?
  end

  test "validates KSA business identifiers" do
    assert build_store(vat_number: "300000000000003", cr_number: "1010000000", unified_number_700: "7001234567").valid?
    assert_equal "300000000000003", build_store(vat_number: "3000 0000 0000 003").vat_number

    assert_not build_store(vat_number: "100000000000003").valid?
    assert_not build_store(vat_number: "30000000000003").valid?
    assert_not build_store(cr_number: "101000000").valid?
    assert_not build_store(unified_number_700: "8001234567").valid?
  end

  test "national address is complete only with all ZATCA fields" do
    assert stores(:elshohail).national_address_complete?
    assert_not stores(:bare).national_address_complete?

    store = stores(:elshohail)
    store.district = nil
    assert_not store.national_address_complete?
  end

  test "localized name and description fall back to the other language" do
    store = build_store(name_ar: "متجر", name_en: "Shop", description_ar: "وصف")
    assert_equal "Shop", store.name(:en)
    assert_equal "متجر", store.name(:ar)
    assert_equal "وصف", store.description(:en)

    assert_equal "متجر", build_store(name_ar: "متجر").name(:en)
  end

  test "error messages use FinaShop labels" do
    I18n.with_locale(:ar) do
      assert_equal "رابط المتجر", Store.human_attribute_name(:subdomain)
    end
  end

  test "finds stores by storefront host" do
    assert_equal stores(:elshohail), Store.find_by_host("elshohail.example.com")
    assert_equal stores(:elshohail), Store.find_by_host("Elshohail.Example.com")
    assert_equal stores(:elshohail), Store.find_by_host("shop.elshohail.sa")
    assert_nil Store.find_by_host("missing.example.com")
    assert_nil Store.find_by_host("elshohail.other.com")
    assert_nil Store.find_by_host("example.com")
  end
end
