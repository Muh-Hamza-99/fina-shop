# Buyer-facing storefront on <slug>.<root domain> or a store's custom domain.
class Storefront::BaseController < ApplicationController
  include StoreResolver
end
