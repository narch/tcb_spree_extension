module SpreeTcb
  module VariantDecorator
    def self.prepended(base)
      base.include SpreeTcb::MultiTenant::TenantScoped
      
      # SKU should be unique per tenant
      base.validates :sku, uniqueness: { scope: :tenant_id }, allow_blank: true
    end
  end
end

Spree::Variant.prepend SpreeTcb::VariantDecorator