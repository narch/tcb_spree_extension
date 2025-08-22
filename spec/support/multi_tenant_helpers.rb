# Helper methods for multi-tenant testing
module MultiTenantHelpers
  def create_tenant(code: 'test_store', name: 'Test Store')
    # Ensure we have a default country
    default_country = Spree::Country.find_by(iso: 'US') || FactoryBot.create(:country, iso: 'US')
    
    Spree::Store.create!(
      code: code,
      name: name,
      url: "#{code}.example.com",
      mail_from_address: "noreply@#{code}.example.com",
      default_currency: 'USD',
      supported_currencies: 'USD',
      default_country: default_country
    )
  end

  def with_tenant(tenant, &block)
    SpreeTcb::MultiTenant.with_tenant(tenant, &block)
  end

  def switch_to_tenant(tenant)
    SpreeTcb::MultiTenant.current_tenant = tenant
  end

  def clear_tenant
    SpreeTcb::MultiTenant.clear_tenant!
  end
end

RSpec.configure do |config|
  config.include MultiTenantHelpers
  
  # Clear tenant after each test
  config.after(:each) do
    SpreeTcb::MultiTenant.clear_tenant!
  end
end