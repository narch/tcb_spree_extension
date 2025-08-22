module SpreeTcb
  module LineItemDecorator
    def self.prepended(base)
      base.include SpreeTcb::MultiTenant::TenantScoped
    end
  end
end

Spree::LineItem.prepend SpreeTcb::LineItemDecorator