module GeocodableAddress
  extend ActiveSupport::Concern

  def full_address
    [
      address1,
      city,
      respond_to?(:state) ? state&.abbr : state_name,
      zipcode,
      country&.name
    ].compact.join(', ')
  end

  def address_changed?
    address1_changed? || city_changed? || state_id_changed? || country_id_changed?
  end

  def geocode
    result = Geocoder.search(full_address).first

    if result
      self.latitude, self.longitude = result.coordinates
    else
      Rails.logger.warn "[Geocoder] No results for: #{full_address}"
    end
  end
end
