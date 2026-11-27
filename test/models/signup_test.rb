require "test_helper"

class SignupTest < ActiveSupport::TestCase
  def build_signup(**attributes)
    Signup.new(store_name_ar: "متجر الرياض", subdomain: "riyadh", name: "Fahad Ali",
      email_address: "fahad@riyadh.example", password: "password123", password_confirmation: "password123", **attributes)
  end

  test "creates a trialing store with its owner" do
    signup = build_signup

    assert_difference -> { Store.count } => 1, -> { User.count } => 1 do
      assert signup.save
    end
    assert signup.store.trialing?
    assert signup.user.owner?
    assert_equal signup.store, signup.user.store
  end

  test "maps store and user errors onto form fields and saves nothing" do
    signup = build_signup(subdomain: "elshohail", email_address: users(:elshohail_owner).email_address)

    assert_no_difference [ "Store.count", "User.count" ] do
      assert_not signup.save
    end
    assert_includes signup.errors[:subdomain], I18n.t("activerecord.errors.models.store.attributes.subdomain.taken")
    assert_includes signup.errors[:email_address], I18n.t("activerecord.errors.models.user.attributes.email_address.taken")
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
