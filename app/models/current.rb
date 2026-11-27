class Current < ActiveSupport::CurrentAttributes
  attribute :session, :store, :customer
  delegate :user, to: :session, allow_nil: true
end
