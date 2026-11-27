require "test_helper"

class Admin::SignupsControllerTest < ActionDispatch::IntegrationTest
  setup { host! Hosts.admin_host }

  def signup_params(**overrides)
    { signup: { store_name_ar: "متجر جدة", store_name_en: "Jeddah Store", subdomain: "jeddah",
                name: "Noura Saleh", email_address: "noura@jeddah.example",
                password: "password123", password_confirmation: "password123", **overrides } }
  end

  test "new" do
    get admin_signup_path
    assert_response :success
    assert_select "form[action=?]", admin_signup_path
  end

  test "create makes the store and owner, signs in and shows the dashboard" do
    assert_difference -> { Store.count } => 1, -> { User.count } => 1 do
      post admin_signup_path, params: signup_params
    end

    assert_redirected_to admin_root_path
    assert cookies[:session_id].present?

    follow_redirect!
    assert_select "#notice", I18n.t("admin.signups.create.created", locale: :ar)
    assert_select "#current_store", "متجر جدة"
  end

  test "create with errors re-renders the form with field errors" do
    assert_no_difference -> { Store.count } do
      post admin_signup_path, params: signup_params(subdomain: "elshohail", password_confirmation: "nope")
    end

    assert_response :unprocessable_entity
    assert_select "#subdomain_error", I18n.t("activerecord.errors.models.store.attributes.subdomain.taken", locale: :ar)
    assert_select "#password_confirmation_error"
    assert_select "input[name=?][value=?]", "signup[subdomain]", "elshohail"
    assert_nil cookies[:session_id]
  end

  test "signed in users are sent to the dashboard" do
    sign_in_as users(:elshohail_owner)
    get admin_signup_path
    assert_redirected_to admin_root_path
  end

  test "signup is only on the admin host" do
    host! Hosts.apex_host
    get "/signup"
    assert_response :not_found

    host! Hosts.store_host(stores(:elshohail))
    get "/signup"
    assert_response :not_found
  end
end
