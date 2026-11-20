require "test_helper"

class HostsTest < ActiveSupport::TestCase
  test "root domain comes from config" do
    assert_equal "example.com", Hosts.root_domain
  end

  test "apex is the bare root domain or www" do
    assert_equal :apex, Hosts.kind("example.com")
    assert_equal :apex, Hosts.kind("www.example.com")
    assert_equal :apex, Hosts.kind("WWW.Example.com")
  end

  test "app subdomain is the merchant admin" do
    assert_equal :admin, Hosts.kind("app.example.com")
  end

  test "other subdomains and custom domains are storefronts" do
    assert_equal :storefront, Hosts.kind("elshohail.example.com")
    assert_equal :storefront, Hosts.kind("shop.elshohail.sa")
    assert_equal :storefront, Hosts.kind("a.b.example.com")
    assert_equal :storefront, Hosts.kind("notexample.com")
  end

  test "subdomain_of returns the single label in front of the root domain" do
    assert_equal "elshohail", Hosts.subdomain_of("elshohail.example.com")
    assert_equal "elshohail", Hosts.subdomain_of("ELSHOHAIL.example.com")
    assert_nil Hosts.subdomain_of("example.com")
    assert_nil Hosts.subdomain_of("a.b.example.com")
    assert_nil Hosts.subdomain_of("shop.elshohail.sa")
    assert_nil Hosts.subdomain_of("evilexample.com")
  end

  test "builds hosts" do
    assert_equal "example.com", Hosts.apex_host
    assert_equal "app.example.com", Hosts.admin_host
    assert_equal "elshohail.example.com", Hosts.store_host(stores(:elshohail))
  end
end
