class AddMultiTenancySupport < ActiveRecord::Migration[7.0]
  def change
    # Core product tables
    tables_to_add_tenant = [
      :spree_products,
      :spree_variants,
      :spree_product_properties,
      :spree_product_option_types,
      :spree_option_values,
      :spree_option_types,
      :spree_properties,
      
      # Taxonomy
      :spree_taxonomies,
      :spree_taxons,
      
      # Orders
      :spree_orders,
      :spree_line_items,
      :spree_shipments,
      :spree_payments,
      :spree_adjustments,
      :spree_return_authorizations,
      
      # Stock
      :spree_stock_locations,
      :spree_stock_items,
      :spree_stock_movements,
      
      # Configuration
      :spree_payment_methods,
      :spree_shipping_methods,
      :spree_shipping_categories,
      :spree_tax_categories,
      :spree_tax_rates,
      :spree_zones,
      :spree_zone_members,
      
      # Promotions
      :spree_promotions,
      :spree_promotion_rules,
      :spree_promotion_actions,
      
      # Users - optional, can be shared across tenants
      :spree_users
    ]
    
    tables_to_add_tenant.each do |table_name|
      if table_exists?(table_name) && !column_exists?(table_name, :tenant_id)
        add_reference table_name, :tenant, foreign_key: { to_table: :spree_stores }, index: true
      end
    end

    # Add composite indexes for better query performance
    add_index :spree_products, [:tenant_id, :slug], unique: true, if_not_exists: true
    add_index :spree_products, [:tenant_id, :available_on], if_not_exists: true
    add_index :spree_orders, [:tenant_id, :number], unique: true, if_not_exists: true
    add_index :spree_orders, [:tenant_id, :completed_at], if_not_exists: true
    add_index :spree_users, [:tenant_id, :email], unique: true, if_not_exists: true
    
    # Join tables that might need tenant_id
    join_tables = [
      :spree_products_taxons,
      :spree_option_values_variants,
      :spree_shipping_methods_zones,
      :spree_products_promotion_rules
    ]
    
    join_tables.each do |table_name|
      if table_exists?(table_name) && !column_exists?(table_name, :tenant_id)
        add_reference table_name, :tenant, foreign_key: { to_table: :spree_stores }, index: true
      end
    end
  end
end