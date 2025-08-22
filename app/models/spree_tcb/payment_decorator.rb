module SpreeTcb
  module PaymentDecorator
    def self.prepended(base)
      base.include SpreeTcb::MultiTenant::TenantScoped
    end
  end
end

Spree::Payment.prepend SpreeTcb::PaymentDecorator