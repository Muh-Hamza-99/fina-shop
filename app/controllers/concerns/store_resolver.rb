# Sets Current.store from the storefront host; unknown hosts are a 404.
module StoreResolver
  extend ActiveSupport::Concern

  included do
    before_action :resolve_store
  end

  private
    def resolve_store
      Current.store = Store.find_by_host(request.host) or raise ActiveRecord::RecordNotFound
    end
end
