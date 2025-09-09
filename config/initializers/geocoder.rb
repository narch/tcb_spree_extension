Geocoder.configure(
  lookup: :opencagedata,
  api_key: Rails.env.production? ? Rails.application.credentials.dig(:geocoder, :opencage_api_key) : "testing_key",
  timeout: 5
)