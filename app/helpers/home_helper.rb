module HomeHelper
  PREVIEW_ORDER_HALALAS = [ 820_000, 1_240_000, 815_000, 315_000, 590_000 ].freeze

  # [initials, name, formatted amount] rows for the landing page dashboard preview.
  def landing_preview_orders
    t("home.index.preview.orders").zip(PREVIEW_ORDER_HALALAS).map do |order, halalas|
      [ order[:initials], order[:name], sar(halalas) ]
    end
  end
end
