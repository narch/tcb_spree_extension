module SpreeTcb
  module ProductDecorator
    def self.prepended(base)
      base.include SpreeTcb::MultiTenant::TenantScoped
      
      # Remove the original slug uniqueness validation
      base._validators[:slug].reject! { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
      base._validate_callbacks.each do |callback|
        if callback.filter.is_a?(ActiveRecord::Validations::UniquenessValidator) && callback.filter.attributes.include?(:slug)
          base._validate_callbacks.delete(callback)
        end
      end
      
      # Add new slug uniqueness validation scoped to tenant
      base.validates :slug, uniqueness: { scope: :tenant_id }, allow_blank: true
      
      # Configure FriendlyId to scope slugs by tenant_id if FriendlyId is being used
      if base.respond_to?(:friendly_id)
        base.friendly_id :slug_candidates, use: [:slugged, :history], slug_column: :slug, scope: :tenant_id
      end
    end
    
    # Override slug candidates to ensure uniqueness within tenant
    def slug_candidates
      [
        :name,
        [:name, :id]
      ]
    end
  end
end

Spree::Product.prepend SpreeTcb::ProductDecorator