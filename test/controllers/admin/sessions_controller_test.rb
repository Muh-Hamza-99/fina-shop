require "test_helper"

class Admin::SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! Hosts.admin_host
    @user = users(:elshohail_owner)
  end

  test "new" do
    get new_admin_session_path
    assert_response :success
  end

  test "create with valid credentials" do
    post admin_session_path, params: { email_address: @user.email_address, password: "password" }

    assert_redirected_to admin_root_url
    assert cookies[:session_id]
  end

  test "create returns to the originally requested admin page" do
    get admin_root_path(locale: "en")
    post admin_session_path, params: { email_address: @user.email_address, password: "password" }

    assert_redirected_to admin_root_url(locale: "en")
  end

  test "create with invalid credentials" do
    post admin_session_path, params: { email_address: @user.email_address, password: "wrong" }

    assert_redirected_to new_admin_session_path
    assert_nil cookies[:session_id]
    follow_redirect!
    assert_select "#alert", I18n.t("admin.sessions.create.invalid_credentials", locale: :ar)
  end

  test "session cookie is host-only so storefronts never receive it" do
    post admin_session_path, params: { email_address: @user.email_address, password: "password" }

    set_cookie = Array(response.headers["Set-Cookie"]).join("\n").lines.find { |line| line.start_with?("session_id=") }
    assert set_cookie, "expected a session_id cookie"
    assert_no_match(/domain=/i, set_cookie)
    assert_match(/httponly/i, set_cookie)
    assert_match(/samesite=lax/i, set_cookie)
  end

  test "destroy" do
    sign_in_as(@user)

    delete admin_session_path

    assert_redirected_to new_admin_session_path
    assert_empty cookies[:session_id]
  end
end
