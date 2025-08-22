module SpreeTcb
  module StoreDecorator
    def self.prepended(base)
      base.class_eval do
        # Add registration_disabled preference with default false
        preference :registration_disabled, :boolean, default: false
        
        # Remove existing associations that we need to redefine
        # Note: has_many :taxons, through: :taxonomies is defined by Spree
        # We need to redefine taxonomies first, then taxons
        
        # Store is the tenant, so it has many tenant-scoped models
        has_many :products, class_name: 'Spree::Product', foreign_key: :tenant_id, dependent: :destroy
        has_many :orders, class_name: 'Spree::Order', foreign_key: :tenant_id, dependent: :destroy
        has_many :taxonomies, class_name: 'Spree::Taxonomy', foreign_key: :tenant_id, dependent: :destroy
        has_many :taxons, through: :taxonomies, class_name: 'Spree::Taxon'
        has_many :stock_locations, class_name: 'Spree::StockLocation', foreign_key: :tenant_id, dependent: :destroy
        has_many :zones, class_name: 'Spree::Zone', foreign_key: :tenant_id, dependent: :destroy
        has_many :shipping_methods, class_name: 'Spree::ShippingMethod', foreign_key: :tenant_id, dependent: :destroy
        has_many :payment_methods, class_name: 'Spree::PaymentMethod', foreign_key: :tenant_id, dependent: :destroy
        has_many :promotions, class_name: 'Spree::Promotion', foreign_key: :tenant_id, dependent: :destroy
        has_many :users, class_name: 'Spree::User', foreign_key: :tenant_id, dependent: :nullify
        
        # No need to modify callbacks - we'll override the methods instead
      end
    end

    def registration_enabled?
      !preferred_registration_disabled
    end

    def registration_disabled?
      preferred_registration_disabled
    end
    
    # Override the original method to work with multi-tenancy
    # This is called after_create, so the store has an ID
    def ensure_default_taxonomies_are_created
      # Skip for now - causing issues with validation
      # Can be called manually after store creation if needed
    end
    
    def ensure_default_automatic_taxons
      # Override if needed - for now just skip
    end
  end
end

Spree::Store.prepend SpreeTcb::StoreDecorator