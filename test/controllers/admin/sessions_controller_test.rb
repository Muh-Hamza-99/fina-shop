require "test_helper"

class Admin::SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! Hosts.admin_host
    @user = users(:elshohail_owner)
  end

  test "signs in with valid credentials, with a host-only cookie" do
    post admin_session_path, params: { email_address: @user.email_address, password: "password" }
    assert_redirected_to admin_root_url

    # No Domain attribute: the cookie is only sent to app.<root>, never to storefronts.
    set_cookie = Array(response.headers["Set-Cookie"]).join("\n").lines.find { |line| line.start_with?("session_id=") }
    assert set_cookie, "expected a session_id cookie"
    assert_no_match(/domain=/i, set_cookie)
    assert_match(/httponly/i, set_cookie)
  end

  test "rejects invalid credentials" do
    post admin_session_path, params: { email_address: @user.email_address, password: "wrong" }
    assert_redirected_to new_admin_session_path
    assert_nil cookies[:session_id]
  end

  test "signs out" do
    sign_in_as(@user)
    delete admin_session_path
    assert_redirected_to new_admin_session_path
    assert_empty cookies[:session_id]
  end
end
