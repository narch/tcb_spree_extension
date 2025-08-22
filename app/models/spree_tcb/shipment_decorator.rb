module SpreeTcb
  module ShipmentDecorator
    def self.prepended(base)
      base.include SpreeTcb::MultiTenant::TenantScoped
      
      # Shipment number should be unique per tenant
      base.validates :number, uniqueness: { scope: :tenant_id }
    end
  end
end

Spree::Shipment.prepend SpreeTcb::ShipmentDecorator