require "application_system_test_case"

class AdminSignInTest < ApplicationSystemTestCase
  test "merchant signs in, moves around the admin and signs out" do
    visit_host Hosts.admin_host, "/?locale=en"
    fill_in "Email", with: users(:elshohail_owner).email_address
    fill_in "Password", with: "password"
    click_on "Sign In", class: "btn-primary"

    assert_selector "h1", text: "Dashboard"
    assert_selector "#current_store", text: stores(:elshohail).name_en
    assert_equal "http://#{Hosts.store_host(stores(:elshohail))}:#{Capybara.current_session.server.port}/",
      find("#visit_store")[:href]

    {
      "Products" => "Products", "Categories" => "Categories", "Quote Requests" => "Quote Requests",
      "Customers" => "Customers", "Analytics" => "Analytics & Insights", "Customize Theme" => "Customize Theme",
      "Store Settings" => "Store Settings", "Billing & Subscription" => "Billing & Subscription", "Dashboard" => "Dashboard"
    }.each do |link, heading|
      within("nav[aria-label='Main navigation']") { click_on link }
      assert_selector "h1", text: heading
      assert_selector "nav a[aria-current=page]", text: link
    end

    find("summary", text: users(:elshohail_owner).name).click
    click_on "Logout"
    assert_selector "h1", text: "Sign In"
  end
end
