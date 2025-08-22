module Spree
  module BaseControllerDecorator
    def self.prepended(base)
      base.include SpreeTcb::MultiTenant::TenantController
    end
  end
end

if defined?(Spree::BaseController)
  Spree::BaseController.prepend Spree::BaseControllerDecorator
end