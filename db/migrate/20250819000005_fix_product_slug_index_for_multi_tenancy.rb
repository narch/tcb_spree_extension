class FixProductSlugIndexForMultiTenancy < ActiveRecord::Migration[7.0]
  def up
    # Remove the existing unique index on slug if it exists
    if index_exists?(:spree_products, :slug)
      remove_index :spree_products, :slug
    end
    
    # Add a new composite unique index on tenant_id and slug
    # This allows the same slug in different tenants
    unless index_exists?(:spree_products, [:tenant_id, :slug], name: 'index_spree_products_on_tenant_id_and_slug')
      add_index :spree_products, [:tenant_id, :slug], unique: true, name: 'index_spree_products_on_tenant_id_and_slug'
    end
  end
  
  def down
    # Remove the composite index
    if index_exists?(:spree_products, [:tenant_id, :slug])
      remove_index :spree_products, [:tenant_id, :slug]
    end
    
    # Restore the original unique index on slug
    add_index :spree_products, :slug, unique: true
  end
end