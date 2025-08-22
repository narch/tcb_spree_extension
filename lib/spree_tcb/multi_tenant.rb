module SpreeTcb
  module MultiTenant
    class << self
      def current_tenant
        Thread.current[:current_tenant]
      end

      def current_tenant=(tenant)
        Thread.current[:current_tenant] = tenant
      end

      def with_tenant(tenant)
        old_tenant = current_tenant
        self.current_tenant = tenant
        yield
      ensure
        self.current_tenant = old_tenant
      end

      def clear_tenant!
        self.current_tenant = nil
      end

      # List of models that should be scoped by tenant
      def tenanted_models
        [
          # Core models
          'Spree::Product',
          'Spree::Variant',
          'Spree::ProductProperty',
          'Spree::ProductOptionType',
          'Spree::OptionValue',
          'Spree::OptionType',
          'Spree::Property',
          
          # Taxonomy
          'Spree::Taxonomy',
          'Spree::Taxon',
          
          # Orders
          'Spree::Order',
          'Spree::LineItem',
          'Spree::Shipment',
          'Spree::Payment',
          'Spree::Adjustment',
          'Spree::ReturnAuthorization',
          
          # Stock
          'Spree::StockLocation',
          'Spree::StockItem',
          'Spree::StockMovement',
          
          # Configuration
          'Spree::PaymentMethod',
          'Spree::ShippingMethod',
          'Spree::ShippingCategory',
          'Spree::TaxCategory',
          'Spree::TaxRate',
          'Spree::Zone',
          'Spree::ZoneMember',
          
          # Promotions
          'Spree::Promotion',
          'Spree::PromotionRule',
          'Spree::PromotionAction',
          
          # Users (optional - can be configured)
          'Spree::User'
        ]
      end

      # Models that should remain global/shared
      def shared_models
        [
          'Spree::Country',
          'Spree::State',
          'Spree::Store', # Stores ARE the tenants
          'Spree::Role'
        ]
      end
    end
  end
end