# Merchant signup: creates a store (on a free trial) and its owner in one transaction.
# Errors from Store and User are copied onto the matching form fields.
class Signup
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :store_name_ar, :string
  attribute :store_name_en, :string
  attribute :subdomain, :string
  attribute :name, :string
  attribute :email_address, :string
  attribute :password, :string
  attribute :password_confirmation, :string

  FIELDS = {
    store: { name_ar: :store_name_ar, name_en: :store_name_en, subdomain: :subdomain },
    user: { name: :name, email_address: :email_address, password: :password, password_confirmation: :password_confirmation }
  }.freeze

  attr_reader :store, :user

  def save
    @store = Store.new(name_ar: store_name_ar, name_en: store_name_en, subdomain: subdomain)
    @user = store.users.build(name: name, email_address: email_address, role: :owner,
      password: password, password_confirmation: password_confirmation.to_s)

    # store.save validates again and saves the owner in the same transaction.
    return true if valid_records? && store.save

    # Copy the latest errors onto the form, including a subdomain or email
    # that another signup took after our first validation.
    valid_records?
    false
  rescue ActiveRecord::RecordNotUnique
    # Another signup inserted the same subdomain or email between validation and insert.
    valid_records?
    false
  end

  private
    def valid_records?
      errors.clear
      [ store.valid?, user.valid? ].all?.tap do
        { store: store, user: user }.each do |record_name, record|
          record.errors.each do |error|
            field = FIELDS[record_name][error.attribute]
            errors.add(field, error.message) if field
          end
        end
      end
    end
end
