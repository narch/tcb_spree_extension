module Spree
  module Admin
    module BaseControllerDecorator
      def self.prepended(base)
        base.include SpreeTcb::MultiTenant::TenantController
      end
    end
  end
end

if defined?(Spree::Admin::BaseController)
  Spree::Admin::BaseController.prepend Spree::Admin::BaseControllerDecorator
end