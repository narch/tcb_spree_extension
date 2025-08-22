module SpreeTcb
  module TaxonDecorator
    def self.prepended(base)
      base.include SpreeTcb::MultiTenant::TenantScoped
      
      # Permalink should be unique per tenant
      base.validates :permalink, uniqueness: { scope: :tenant_id }
    end
  end
end

Spree::Taxon.prepend SpreeTcb::TaxonDecorator