require "test_helper"

class Admin::PasswordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! Hosts.admin_host
    @user = users(:elshohail_owner)
  end

  test "new" do
    get new_admin_password_path
    assert_response :success
  end

  test "create" do
    post admin_passwords_path, params: { email_address: @user.email_address }
    assert_enqueued_email_with PasswordsMailer, :reset, args: [ @user ]
    assert_redirected_to new_admin_session_path

    follow_redirect!
    assert_select "#notice", I18n.t("admin.passwords.create.reset_link_sent", locale: :ar)
  end

  test "create for an unknown user redirects but sends no mail" do
    post admin_passwords_path, params: { email_address: "missing-user@example.com" }
    assert_enqueued_emails 0
    assert_redirected_to new_admin_session_path
  end

  test "edit" do
    get edit_admin_password_path(@user.password_reset_token)
    assert_response :success
  end

  test "edit with invalid password reset token" do
    get edit_admin_password_path("invalid token")
    assert_redirected_to new_admin_password_path

    follow_redirect!
    assert_select "#alert", I18n.t("admin.passwords.invalid_link", locale: :ar)
  end

  test "update resets the password and signs out other sessions" do
    @user.sessions.create!

    assert_changes -> { @user.reload.password_digest } do
      put admin_password_path(@user.password_reset_token), params: { password: "new-password", password_confirmation: "new-password" }
      assert_redirected_to new_admin_session_path
    end
    assert_empty @user.sessions

    follow_redirect!
    assert_select "#notice", I18n.t("admin.passwords.update.password_changed", locale: :ar)
  end

  test "update with non matching passwords" do
    token = @user.password_reset_token
    assert_no_changes -> { @user.reload.password_digest } do
      put admin_password_path(token), params: { password: "new-password", password_confirmation: "different" }
      assert_redirected_to edit_admin_password_path(token)
    end
  end

  test "update with a too short password" do
    token = @user.password_reset_token
    assert_no_changes -> { @user.reload.password_digest } do
      put admin_password_path(token), params: { password: "short", password_confirmation: "short" }
      assert_redirected_to edit_admin_password_path(token)
    end
  end
end
