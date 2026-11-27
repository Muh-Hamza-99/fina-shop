require "test_helper"

class AdminAccessTest < ActionDispatch::IntegrationTest
  test "admin requires sign in" do
    host! Hosts.admin_host
    get admin_root_path
    assert_redirected_to new_admin_session_path
  end

  test "store comes from the signed-in user, not the host or params" do
    host! Hosts.admin_host
    sign_in_as users(:bare_owner)

    get admin_root_path, params: { store_id: stores(:elshohail).id, subdomain: "elshohail" }
    assert_select "#current_store", stores(:bare).name_ar
  end

  test "auth and signup routes only exist on the admin host" do
    [ Hosts.apex_host, Hosts.store_host(stores(:elshohail)) ].each do |host|
      host! host
      %w[/session/new /signup].each do |path|
        get path
        assert_response :not_found, "#{path} on #{host}"
      end
    end
  end
end
