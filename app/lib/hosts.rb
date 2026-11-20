# Classifies request hosts against the configured root domain:
#
#   fina.shop, www.fina.shop  -> :apex        (marketing, signup)
#   app.fina.shop             -> :admin       (merchant admin)
#   elshohail.fina.shop       -> :storefront  (store found by subdomain)
#   shop.example.com          -> :storefront  (store found by custom domain)
module Hosts
  ADMIN_SUBDOMAIN = "app"
  APEX_SUBDOMAINS = %w[www].freeze

  def self.root_domain
    Rails.configuration.x.root_domain
  end

  def self.kind(host)
    host = host.to_s.downcase
    subdomain = subdomain_of(host)

    if host == root_domain || APEX_SUBDOMAINS.include?(subdomain)
      :apex
    elsif subdomain == ADMIN_SUBDOMAIN
      :admin
    else
      :storefront
    end
  end

  def self.apex?(host) = kind(host) == :apex
  def self.admin?(host) = kind(host) == :admin
  def self.storefront?(host) = kind(host) == :storefront

  # The single label in front of the root domain, or nil for the apex,
  # nested subdomains and other domains.
  def self.subdomain_of(host)
    label = host.to_s.downcase.delete_suffix(".#{root_domain}")
    label unless label == host.to_s.downcase || label.include?(".")
  end

  def self.apex_host = root_domain
  def self.admin_host = "#{ADMIN_SUBDOMAIN}.#{root_domain}"
  def self.store_host(store) = "#{store.subdomain}.#{root_domain}"

  # Route constraints
  Apex = ->(request) { apex?(request.host) }
  Admin = ->(request) { admin?(request.host) }
  Storefront = ->(request) { storefront?(request.host) }
end
