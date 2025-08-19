Geocoder.configure(
  lookup: :opencagedata,
  api_key: Rails.application.credentials.dig(:geocoder, :opencage_api_key),
  timeout: 5
)