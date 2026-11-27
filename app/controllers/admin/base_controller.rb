# Merchant admin on app.<root domain>. The store always comes from the
# signed-in user, never from the request host.
class Admin::BaseController < ApplicationController
  include Authentication

  layout "admin"

  before_action :set_current_store

  private
    def set_current_store
      Current.store = Current.user&.store
    end
end
