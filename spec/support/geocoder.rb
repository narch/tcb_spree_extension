# Disable Geocoder in test environment
Geocoder.configure(lookup: :test)

# Default stub
Geocoder::Lookup::Test.set_default_stub(
  [
    {
      'coordinates' => [40.7143528, -74.0059731],
      'address' => 'New York, NY, USA',
      'state' => 'New York',
      'state_code' => 'NY',
      'country' => 'United States',
      'country_code' => 'US'
    }
  ]
)