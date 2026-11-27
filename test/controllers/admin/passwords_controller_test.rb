require "test_helper"

class Admin::PasswordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! Hosts.admin_host
    @user = users(:elshohail_owner)
  end

  test "requesting a reset emails known users only" do
    post admin_passwords_path, params: { email_address: @user.email_address }
    assert_enqueued_email_with PasswordsMailer, :reset, args: [ @user ]
    assert_redirected_to new_admin_session_path

    post admin_passwords_path, params: { email_address: "missing-user@example.com" }
    assert_enqueued_emails 1
  end

  test "invalid reset token is rejected" do
    get edit_admin_password_path("invalid token")
    assert_redirected_to new_admin_password_path
  end

  test "resetting the password signs out existing sessions" do
    @user.sessions.create!

    assert_changes -> { @user.reload.password_digest } do
      put admin_password_path(@user.password_reset_token), params: { password: "new-password", password_confirmation: "new-password" }
    end
    assert_redirected_to new_admin_session_path
    assert_empty @user.sessions
  end
end
