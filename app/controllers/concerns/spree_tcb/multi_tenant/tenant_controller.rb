module SpreeTcb
  module MultiTenant
    module TenantController
      extend ActiveSupport::Concern

      included do
        prepend_before_action :set_current_tenant
        after_action :clear_current_tenant
        
        helper_method :current_tenant
      end

      private

      def set_current_tenant
        # Use the current_store as the tenant
        # Spree already sets current_store based on domain
        if current_store
          SpreeTcb::MultiTenant.current_tenant = current_store
          
          # For admin controllers, check if user has access to this tenant
          if self.class.name.include?('Admin') && defined?(spree_current_user) && spree_current_user
            unless user_can_access_tenant?(spree_current_user, current_store)
              flash[:error] = "You don't have access to this store"
              redirect_to main_app.root_path
            end
          end
        elsif Rails.env.production?
          # In production, we should always have a store/tenant
          raise 'No store found for domain'
        end
      end

      def clear_current_tenant
        # Clear thread-local tenant after request
        SpreeTcb::MultiTenant.clear_tenant!
      end

      def current_tenant
        SpreeTcb::MultiTenant.current_tenant
      end

      def user_can_access_tenant?(user, tenant)
        # Super admins can access all tenants
        return true if user.has_spree_role?('admin')
        
        # Check if user belongs to this tenant
        # This assumes we'll add a tenant relationship to users
        if user.respond_to?(:tenant_id)
          user.tenant_id == tenant.id
        else
          # If users aren't tenant-scoped, allow access
          true
        end
      end

      # Helper to switch tenant context (useful for admin)
      def with_tenant(tenant, &block)
        SpreeTcb::MultiTenant.with_tenant(tenant, &block)
      end
    end
  end
end