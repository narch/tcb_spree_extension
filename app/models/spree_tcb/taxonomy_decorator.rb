module SpreeTcb
  module TaxonomyDecorator
    def self.prepended(base)
      base.include SpreeTcb::MultiTenant::TenantScoped
    end
  end
end

Spree::Taxonomy.prepend SpreeTcb::TaxonomyDecorator