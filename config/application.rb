require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module FinaShop
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "Riyadh"
    # config.eager_load_paths << Rails.root.join("extras")

    # Arabic-first, bilingual storefront and admin.
    config.i18n.available_locales = %i[ar en]
    config.i18n.default_locale = :ar
    config.i18n.fallbacks = [ :en ]

    # Root domain for host routing (see Hosts): apex = marketing/signup,
    # app.<root> = merchant admin, <slug>.<root> = storefronts.
    config.x.root_domain = ENV.fetch("ROOT_DOMAIN", "fina.shop")
  end
end
