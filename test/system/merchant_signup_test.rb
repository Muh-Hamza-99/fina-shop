require "application_system_test_case"

class MerchantSignupTest < ApplicationSystemTestCase
  test "merchant signs up from the landing page and lands on their dashboard" do
    visit root_path(locale: :en)
    click_on "Start your store free"

    fill_in "Store Name (Arabic)", with: "متجر الدمام"
    fill_in "Store Name (English) (optional)", with: "Dammam Store"
    fill_in "Store URL", with: "Dammam"
    assert_text "Your store URL will be: dammam.#{Hosts.root_domain}"

    fill_in "Full Name", with: "Khalid Omar"
    fill_in "Email", with: "khalid@dammam.example"
    fill_in "Password", with: "password123"
    fill_in "Confirm Password", with: "password123"
    click_on "Create Account"

    assert_selector "#notice", text: "Your store has been created successfully!"
    assert_selector "#current_store", text: "Dammam Store"

    visit_host Hosts.store_host(Store.find_by!(subdomain: "dammam")), "/?locale=en"
    assert_selector "h1", text: "Dammam Store"
  end
end
