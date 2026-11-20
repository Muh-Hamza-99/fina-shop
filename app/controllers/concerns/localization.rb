# Resolves the request locale from, in order: ?locale param (persisted to a
# cookie), the locale cookie, the Accept-Language header, then the default.
module Localization
  extend ActiveSupport::Concern

  included do
    around_action :switch_locale
  end

  private
    def switch_locale(&action)
      I18n.with_locale(resolve_locale, &action)
    end

    def resolve_locale
      if (locale = supported_locale(params[:locale]))
        cookies[:locale] = { value: locale, expires: 1.year }
        locale
      else
        supported_locale(cookies[:locale]) || locale_from_accept_language || I18n.default_locale
      end
    end

    def locale_from_accept_language
      request.headers["Accept-Language"].to_s.split(",").lazy
        .map { |entry| supported_locale(entry.split(";").first.to_s.strip.split("-").first) }
        .find(&:itself)
    end

    def supported_locale(value)
      I18n.available_locales.find { |locale| locale.to_s == value.to_s.downcase }
    end
end
