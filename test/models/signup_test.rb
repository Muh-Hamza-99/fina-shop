require "test_helper"

class SignupTest < ActiveSupport::TestCase
  def build_signup(**attributes)
    Signup.new(store_name_ar: "متجر الرياض", store_name_en: "Riyadh Store", subdomain: "riyadh",
      name: "Fahad Ali", email_address: "fahad@riyadh.example", password: "password123",
      password_confirmation: "password123", **attributes)
  end

  test "creates a trialing store with its owner" do
    signup = build_signup

    assert_difference -> { Store.count } => 1, -> { User.count } => 1 do
      assert signup.save
    end

    assert signup.store.trialing?
    assert signup.store.trial_ends_at.future?
    assert_equal "riyadh", signup.store.subdomain
    assert signup.user.owner?
    assert_equal signup.store, signup.user.store
    assert signup.user.authenticate("password123")
  end

  test "maps store errors onto form fields" do
    signup = build_signup(store_name_ar: "", subdomain: "Bad Slug!")

    assert_no_difference -> { Store.count } do
      assert_not signup.save
    end
    assert signup.errors.added?(:store_name_ar, :blank) || signup.errors[:store_name_ar].any?
    assert_includes signup.errors[:subdomain], I18n.t("activerecord.errors.models.store.attributes.subdomain.invalid")
  end

  test "taken and reserved subdomains are unavailable" do
    message = I18n.t("activerecord.errors.models.store.attributes.subdomain.taken")

    signup = build_signup(subdomain: "elshohail")
    assert_not signup.save
    assert_includes signup.errors[:subdomain], message

    signup = build_signup(subdomain: "admin")
    assert_not signup.save
    assert_includes signup.errors[:subdomain], message
  end

  test "maps user errors onto form fields" do
    signup = build_signup(name: "a", email_address: users(:elshohail_owner).email_address,
      password: "short", password_confirmation: "different")

    assert_no_difference [ "Store.count", "User.count" ] do
      assert_not signup.save
    end
    assert_includes signup.errors[:name], I18n.t("activerecord.errors.models.user.attributes.name.too_short")
    assert_includes signup.errors[:email_address], I18n.t("activerecord.errors.models.user.attributes.email_address.taken")
    assert_includes signup.errors[:password], I18n.t("activerecord.errors.models.user.attributes.password.too_short")
    assert_includes signup.errors[:password_confirmation], I18n.t("activerecord.errors.models.user.attributes.password_confirmation.confirmation")
  end

  test "requires the password confirmation" do
    signup = build_signup(password_confirmation: nil)
    assert_not signup.save
    assert signup.errors[:password_confirmation].any?
  end

  test "a concurrent signup taking the subdomain is reported as taken, not raised" do
    signup = build_signup
    # Simulate another request inserting the same subdomain after validation passed.
    signup.singleton_class.prepend(Module.new do
      def valid_records?
        super.tap { |valid| Store.insert!({ name_ar: "سباق", subdomain: "riyadh" }) if valid && !Store.exists?(subdomain: "riyadh") }
      end
    end)

    assert_no_difference -> { User.count } do
      assert_not signup.save
    end
    assert_includes signup.errors[:subdomain], I18n.t("activerecord.errors.models.store.attributes.subdomain.taken")
  end
end
