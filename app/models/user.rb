# Merchant staff. Each user belongs to exactly one store and signs in on app.<root domain>.
class User < ApplicationRecord
  has_secure_password
  belongs_to :store
  has_many :sessions, dependent: :destroy

  enum :role, %w[owner staff].index_by(&:itself), validate: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :name, with: ->(name) { name.squish }

  validates :name, presence: true, length: { minimum: 2 }
  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, allow_nil: true
end
