class Store < ApplicationRecord
  TRIAL_LENGTH = 14.days
  RESERVED_SUBDOMAINS = %w[
    admin api app assets blog cdn dev docs fina ftp help mail shop staging static status support test www
  ].freeze
  NATIONAL_ADDRESS_FIELDS = %i[region city district street building_number postal_code].freeze

  has_many :users, dependent: :destroy

  enum :subscription_status, %w[trialing active past_due canceled].index_by(&:itself), validate: true

  normalizes :subdomain, :custom_domain, with: ->(value) { value.strip.downcase.presence }
  normalizes :email, with: ->(value) { value.strip.downcase.presence }
  normalizes :phone, :whatsapp_phone, with: ->(value) { normalize_phone(value) }
  normalizes :website, with: ->(value) { normalize_website(value) }
  normalizes :country_code, with: ->(value) { value.strip.upcase }
  normalizes :name_ar, :name_en, :region, :city, :district, :street, with: ->(value) { value.squish.presence }
  normalizes :building_number, :postal_code, :unified_number_700, :cr_number, :vat_number,
    with: ->(value) { value.gsub(/\s/, "").presence }

  validates :name_ar, presence: true
  validates :subdomain, presence: true, uniqueness: true,
    format: { with: /\A[a-z0-9](?:[a-z0-9-]{1,30})[a-z0-9]\z/ },
    exclusion: { in: RESERVED_SUBDOMAINS }
  validates :custom_domain, uniqueness: true, allow_nil: true,
    format: { with: /\A(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z]{2,}\z/ }
  validate :custom_domain_not_fina_shop

  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_nil: true
  validates :phone, :whatsapp_phone, format: { with: /\A\+[1-9]\d{7,14}\z/ }, allow_nil: true
  validates :website, format: { with: %r{\Ahttps?://[^\s/]+\.[^\s]+\z} }, allow_nil: true
  validates :country_code, format: { with: /\A[A-Z]{2}\z/ }

  with_options if: :saudi? do
    validates :building_number, format: { with: /\A\d{4}\z/ }, allow_nil: true
    validates :postal_code, format: { with: /\A\d{5}\z/ }, allow_nil: true
  end

  validates :vat_number, format: { with: /\A3\d{13}3\z/ }, allow_nil: true
  validates :cr_number, format: { with: /\A\d{10}\z/ }, allow_nil: true
  validates :unified_number_700, format: { with: /\A7\d{9}\z/ }, allow_nil: true

  before_validation :start_trial, on: :create

  # Finds the store served on a storefront host: <subdomain>.<root domain> or a custom domain.
  def self.find_by_host(host)
    host = host.to_s.downcase
    if (subdomain = Hosts.subdomain_of(host))
      find_by(subdomain: subdomain)
    else
      find_by(custom_domain: host)
    end
  end

  def self.normalize_phone(value)
    parsed = Phonelib.parse(value)
    parsed.valid? ? parsed.e164 : value.strip.presence
  end

  def self.normalize_website(value)
    value = value.strip
    return if value.blank?

    value.match?(%r{\Ahttps?://}i) ? value : "https://#{value}"
  end

  def name(locale = I18n.locale)
    (locale.to_sym == :en && name_en.presence) || name_ar
  end

  def description(locale = I18n.locale)
    locale.to_sym == :en ? description_en.presence || description_ar : description_ar.presence || description_en
  end

  def saudi?
    country_code == "SA"
  end

  def national_address_complete?
    NATIONAL_ADDRESS_FIELDS.all? { |field| self[field].present? }
  end

  private
    def start_trial
      self.trial_ends_at ||= TRIAL_LENGTH.from_now if trialing?
    end

    def custom_domain_not_fina_shop
      if custom_domain&.then { |domain| domain == "fina.shop" || domain.end_with?(".fina.shop") }
        errors.add(:custom_domain, :exclusion)
      end
    end
end
