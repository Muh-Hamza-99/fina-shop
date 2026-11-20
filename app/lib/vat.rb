# Saudi VAT at 15%, rounded half-up to the nearest halala.
module Vat
  RATE_PERCENT = 15

  # Vat.amount(10_000) # => 1_500
  def self.amount(taxable_halalas)
    raise ArgumentError, "taxable amount must be a non-negative Integer" unless taxable_halalas.is_a?(Integer) && taxable_halalas >= 0

    ((taxable_halalas * RATE_PERCENT) + 50) / 100
  end
end
