module SpreeTcb
  module StockLocationDecorator
    include GeocodableAddress

    def self.prepended(base)
      base.geocoded_by :full_address
      base.after_validation :geocode, if: -> { address_changed? || new_record? }
    end
  end
end

Spree::StockLocation.prepend SpreeTcb::StockLocationDecorator