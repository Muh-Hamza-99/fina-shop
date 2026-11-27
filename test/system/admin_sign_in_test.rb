require "application_system_test_case"

class AdminSignInTest < ApplicationSystemTestCase
  test "merchant signs in on the admin host and signs out" do
    visit_host Hosts.admin_host, "/?locale=en"
    assert_selector "h1", text: "Sign In"

    fill_in "Email", with: users(:elshohail_owner).email_address
    fill_in "Password", with: "password"
    click_on "Sign In", class: "btn-primary"

    assert_selector "h1", text: "Dashboard"
    assert_selector "#current_store", text: stores(:elshohail).name_en

    click_on "Logout"
    assert_selector "h1", text: "Sign In"
  end

  test "wrong password shows an error" do
    visit_host Hosts.admin_host, "/session/new?locale=en"
    fill_in "Email", with: users(:elshohail_owner).email_address
    fill_in "Password", with: "wrong"
    click_on "Sign In", class: "btn-primary"

    assert_selector "#alert", text: "Invalid credentials."
  end
end
