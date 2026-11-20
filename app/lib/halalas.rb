# Money is stored as integer halalas (1 SAR = 100 halalas). Never use floats.
module Halalas
  PER_SAR = 100

  ARABIC_DIGITS = "٠١٢٣٤٥٦٧٨٩۰۱۲۳۴۵۶۷۸۹"
  LATIN_DIGITS  = "01234567890123456789"
  SAR_PATTERN = /\A-?\d+(\.\d{1,2})?\z/

  # Halalas.format(123450, locale: :ar) # => "1,234.50 ⃁"
  # Halalas.format(123450, locale: :en) # => "⃁ 1,234.50"
  def self.format(halalas, locale: I18n.locale)
    ActiveSupport::NumberHelper.number_to_currency(
      BigDecimal(halalas.to_i) / PER_SAR,
      unit: I18n.t("currency.sar", locale: locale),
      format: locale.to_sym == :ar ? "%n %u" : "%u %n",
      negative_format: locale.to_sym == :ar ? "-%n %u" : "-%u %n",
      precision: 2, delimiter: ",", separator: "."
    )
  end

  # Parses a SAR amount from user input into halalas. Accepts thousands
  # separators and Arabic-Indic digits. Raises ArgumentError on anything else,
  # including floats and more than 2 decimal places.
  #
  # Halalas.from_sar("1,234.5") # => 123450
  # Halalas.from_sar("١٢٣٫٥٠")  # => 12350
  def self.from_sar(value)
    return value * PER_SAR if value.is_a?(Integer)
    raise ArgumentError, "floats are not allowed for money: #{value.inspect}" if value.is_a?(Float)

    normalized = value.to_s.strip.tr(ARABIC_DIGITS, LATIN_DIGITS).tr("٫", ".").delete(",٬ ")
    raise ArgumentError, "invalid SAR amount: #{value.inspect}" unless normalized.match?(SAR_PATTERN)

    (BigDecimal(normalized) * PER_SAR).to_i
  end
end
