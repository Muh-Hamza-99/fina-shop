require "test_helper"

class UserTest < ActiveSupport::TestCase
  def build_user(**attributes)
    User.new(store: stores(:bare), name: "New User", email_address: "new@example.com", password: "password1", **attributes)
  end

  test "fixtures are valid" do
    assert users(:elshohail_owner).valid?
  end

  test "downcases and strips email_address" do
    assert_equal "downcased@example.com", build_user(email_address: " DOWNCASED@EXAMPLE.COM ").email_address
  end

  test "requires a store" do
    assert_not build_user(store: nil).valid?
  end

  test "email is required, valid and unique across all stores" do
    assert_not build_user(email_address: "").valid?
    assert_not build_user(email_address: "not-an-email").valid?

    user = build_user(email_address: users(:elshohail_owner).email_address.upcase)
    assert_not user.valid?
    assert user.errors.added?(:email_address, :taken, value: users(:elshohail_owner).email_address)
  end

  test "name is required" do
    assert_not build_user(name: " ").valid?
    assert_not build_user(name: "a").valid?
  end

  test "password must be at least 8 characters" do
    assert_not build_user(password: "short").valid?
    assert build_user(password: "longenough").valid?
  end

  test "defaults to staff and only allows known roles" do
    assert build_user.staff?
    assert_not build_user(role: "admin").valid?
  end
end
