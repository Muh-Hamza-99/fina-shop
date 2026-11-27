require "test_helper"

# Chrome 158 rejects Storage.clearDataForOrigin with origin "*", which Capybara 3.40
# sends on every reset. Clear cookies via Network.clearBrowserCookies instead so
# sessions never leak between tests. Remove once Capybara ships a fix.
module ChromeResetCookieFix
  def execute_cdp(cmd, params = {})
    if cmd == "Storage.clearDataForOrigin" && params[:origin] == "*"
      super("Network.clearBrowserCookies")
    else
      super
    end
  end
end
require "capybara/selenium/driver"
require "capybara/selenium/driver_specializations/chrome_driver"
Capybara::Selenium::Driver::ChromeDriver.prepend(ChromeResetCookieFix)

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Resolve the test root domain and all its subdomains to the local test server,
  # so system tests can visit apex, app. and store subdomains without DNS.
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ] do |options|
    options.add_argument("--host-resolver-rules=MAP #{Hosts.root_domain} 127.0.0.1, MAP *.#{Hosts.root_domain} 127.0.0.1")
  end

  Capybara.server_host = "127.0.0.1"
  Capybara.always_include_port = true
  Capybara.app_host = "http://#{Hosts.apex_host}"

  def visit_host(host, path = "/")
    visit "http://#{host}#{path}"
  end
end
