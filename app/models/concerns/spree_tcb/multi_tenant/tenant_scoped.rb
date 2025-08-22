module SpreeTcb
  module MultiTenant
    module TenantScoped
      extend ActiveSupport::Concern

      included do
        belongs_to :tenant, class_name: 'Spree::Store', optional: false
        
        # Default scope to filter by current tenant
        default_scope lambda {
          if SpreeTcb::MultiTenant.current_tenant
            where(tenant_id: SpreeTcb::MultiTenant.current_tenant.id)
          else
            # In development/test, show all if no tenant set
            # In production, this should raise an error
            if Rails.env.production?
              raise 'No tenant set for tenant-scoped query'
            else
              all
            end
          end
        }

        # Automatically set tenant on create
        before_validation :assign_tenant, on: :create
        
        # Validate tenant matches current tenant (security check)
        validate :tenant_matches_current, if: :tenant_id_changed?
      end

      class_methods do
        # Allow queries without tenant scope when explicitly needed
        def unscoped_all
          unscoped { all }
        end

        # Query within a specific tenant's scope
        def for_tenant(tenant)
          unscoped.where(tenant_id: tenant.id)
        end

        # Check if model has tenant scope
        def tenant_scoped?
          true
        end
      end

      private

      def assign_tenant
        self.tenant_id ||= SpreeTcb::MultiTenant.current_tenant&.id
      end

      def tenant_matches_current
        return true if SpreeTcb::MultiTenant.current_tenant.nil? # Allow in tests/console
        
        if tenant_id != SpreeTcb::MultiTenant.current_tenant.id
          errors.add(:tenant_id, "does not match current tenant")
        end
      end
    end
  end
end