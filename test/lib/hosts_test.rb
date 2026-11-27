require "test_helper"

class HostsTest < ActiveSupport::TestCase
  test "classifies hosts against the root domain" do
    assert_equal :apex, Hosts.kind("example.com")
    assert_equal :apex, Hosts.kind("www.example.com")
    assert_equal :admin, Hosts.kind("app.example.com")
    assert_equal :storefront, Hosts.kind("elshohail.example.com")
    assert_equal :storefront, Hosts.kind("shop.elshohail.sa")

    assert_equal "elshohail", Hosts.subdomain_of("elshohail.example.com")
    assert_nil Hosts.subdomain_of("a.b.example.com")
    assert_nil Hosts.subdomain_of("evilexample.com")
  end
end
