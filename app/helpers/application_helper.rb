module ApplicationHelper
  RTL_LOCALES = %i[ar].freeze

  def text_direction(locale = I18n.locale)
    RTL_LOCALES.include?(locale.to_sym) ? "rtl" : "ltr"
  end
end
