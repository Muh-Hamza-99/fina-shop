require "test_helper"

class Admin::SignupsControllerTest < ActionDispatch::IntegrationTest
  setup { host! Hosts.admin_host }

  def signup_params(**overrides)
    { signup: { store_name_ar: "متجر جدة", subdomain: "jeddah", name: "Noura Saleh", email_address: "noura@jeddah.example",
                password: "password123", password_confirmation: "password123", **overrides } }
  end

  test "creates the store and owner, then signs in" do
    assert_difference -> { Store.count } => 1, -> { User.count } => 1 do
      post admin_signup_path, params: signup_params
    end
    assert_redirected_to admin_root_path

    follow_redirect!
    assert_select "#current_store", "متجر جدة"
  end

  test "re-renders the form with field errors" do
    assert_no_difference -> { Store.count } do
      post admin_signup_path, params: signup_params(subdomain: "elshohail")
    end
    assert_response :unprocessable_entity
    assert_select "#subdomain_error", I18n.t("activerecord.errors.models.store.attributes.subdomain.taken", locale: :ar)
    assert_nil cookies[:session_id]
  end
end
