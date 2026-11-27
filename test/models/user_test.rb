require "test_helper"

class UserTest < ActiveSupport::TestCase
  def build_user(**attributes)
    User.new(store: stores(:bare), name: "New User", email_address: "new@example.com", password: "password1", **attributes)
  end

  test "email is normalized and unique across all stores" do
    assert_equal "a@example.com", build_user(email_address: " A@Example.COM ").email_address
    assert_not build_user(email_address: users(:elshohail_owner).email_address.upcase).valid?
  end

  test "password must be at least 8 characters" do
    assert_not build_user(password: "short").valid?
  end
end
