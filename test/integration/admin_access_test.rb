require "test_helper"

class AdminAccessTest < ActionDispatch::IntegrationTest
  test "admin requires sign in" do
    host! Hosts.admin_host
    get admin_root_path
    assert_redirected_to new_admin_session_path
  end

  test "signed in users see their own store" do
    host! Hosts.admin_host
    sign_in_as users(:elshohail_owner)

    get admin_root_path
    assert_response :success
    assert_select "#current_store", stores(:elshohail).name_ar
  end

  test "store comes from the user, not the host or params" do
    host! Hosts.admin_host
    sign_in_as users(:bare_owner)

    get admin_root_path, params: { store_id: stores(:elshohail).id, subdomain: "elshohail" }
    assert_select "#current_store", stores(:bare).name_ar
  end

  test "auth routes do not exist on storefront hosts" do
    host! Hosts.store_host(stores(:elshohail))
    get "/session/new"
    assert_response :not_found

    post "/session", params: { email_address: users(:elshohail_owner).email_address, password: "password" }
    assert_response :not_found
  end

  test "auth routes do not exist on the apex" do
    host! Hosts.apex_host
    get "/session/new"
    assert_response :not_found
  end

  test "storefronts do not require sign in" do
    host! Hosts.store_host(stores(:elshohail))
    get "/"
    assert_response :success
  end
end
