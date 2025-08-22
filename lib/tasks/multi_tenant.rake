namespace :spree_tcb do
  namespace :multi_tenant do
    desc "Assign existing data to all tenants (stores) - loops through each store"
    task assign_tenant_ids: :environment do
      puts "Starting tenant_id assignment for existing records..."
      
      if Spree::Store.count == 0
        puts "No stores found. Please create at least one store first."
        exit 1
      end
      
      Spree::Store.find_each do |store|
        puts "\nProcessing Store: #{store.name} (ID: #{store.id}, Code: #{store.code})"
        
        # For single store setup, assign all records to that store
        # For multi-store, you may need custom logic based on existing associations
        
        # Orders already have store_id, use that for related records
        order_ids = Spree::Order.where(store_id: store.id).pluck(:id)
        
        # Products - in single store, all products belong to the store
        # In multi-store, you might want to check store_products association
        if Spree::Store.count == 1
          count = Spree::Product.where(tenant_id: nil).update_all(tenant_id: store.id)
          puts "  - Updated #{count} products"
          
          count = Spree::Variant.where(tenant_id: nil).update_all(tenant_id: store.id)
          puts "  - Updated #{count} variants"
        else
          # For multi-store, only update products associated with this store
          if store.respond_to?(:products)
            product_ids = store.products.pluck(:id)
            count = Spree::Product.where(id: product_ids, tenant_id: nil).update_all(tenant_id: store.id)
            puts "  - Updated #{count} products"
            
            count = Spree::Variant.where(product_id: product_ids, tenant_id: nil).update_all(tenant_id: store.id)
            puts "  - Updated #{count} variants"
          end
        end
        
        # Orders and related records
        if order_ids.any?
          count = Spree::Order.where(id: order_ids, tenant_id: nil).update_all(tenant_id: store.id)
          puts "  - Updated #{count} orders"
          
          count = Spree::LineItem.where(order_id: order_ids, tenant_id: nil).update_all(tenant_id: store.id)
          puts "  - Updated #{count} line items"
          
          count = Spree::Shipment.where(order_id: order_ids, tenant_id: nil).update_all(tenant_id: store.id)
          puts "  - Updated #{count} shipments"
          
          count = Spree::Payment.where(order_id: order_ids, tenant_id: nil).update_all(tenant_id: store.id)
          puts "  - Updated #{count} payments"
        end
        
        # Taxonomies and Taxons
        if Spree::Store.count == 1 || !store.respond_to?(:taxonomies)
          count = Spree::Taxonomy.where(tenant_id: nil).update_all(tenant_id: store.id)
          puts "  - Updated #{count} taxonomies"
          
          taxonomy_ids = Spree::Taxonomy.where(tenant_id: store.id).pluck(:id)
          count = Spree::Taxon.where(taxonomy_id: taxonomy_ids, tenant_id: nil).update_all(tenant_id: store.id)
          puts "  - Updated #{count} taxons"
        else
          # For multi-store with taxonomy associations
          taxonomy_ids = store.taxonomies.pluck(:id)
          count = Spree::Taxonomy.where(id: taxonomy_ids, tenant_id: nil).update_all(tenant_id: store.id)
          puts "  - Updated #{count} taxonomies"
          
          count = Spree::Taxon.where(taxonomy_id: taxonomy_ids, tenant_id: nil).update_all(tenant_id: store.id)
          puts "  - Updated #{count} taxons"
        end
        
        # Configuration records - usually shared in multi-store but assigned in single store
        if Spree::Store.count == 1
          models_to_update = [
            Spree::StockLocation,
            Spree::Zone,
            Spree::ShippingMethod,
            Spree::PaymentMethod,
            Spree::Promotion,
            Spree::TaxCategory,
            Spree::TaxRate,
            Spree::ShippingCategory,
            Spree::OptionType,
            Spree::Property
          ]
          
          models_to_update.each do |model|
            if model.column_names.include?('tenant_id')
              count = model.where(tenant_id: nil).update_all(tenant_id: store.id)
              puts "  - Updated #{count} #{model.name.demodulize.underscore.humanize.downcase}"
            end
          end
          
          # Handle related records
          if Spree::StockLocation.column_names.include?('tenant_id')
            stock_location_ids = Spree::StockLocation.where(tenant_id: store.id).pluck(:id)
            
            if Spree::StockItem.column_names.include?('tenant_id')
              count = Spree::StockItem.where(stock_location_id: stock_location_ids, tenant_id: nil).update_all(tenant_id: store.id)
              puts "  - Updated #{count} stock items"
            end
            
            if Spree::StockMovement.column_names.include?('tenant_id')
              stock_item_ids = Spree::StockItem.where(stock_location_id: stock_location_ids).pluck(:id)
              count = Spree::StockMovement.where(stock_item_id: stock_item_ids, tenant_id: nil).update_all(tenant_id: store.id)
              puts "  - Updated #{count} stock movements"
            end
          end
          
          # Zone Members
          if Spree::Zone.column_names.include?('tenant_id') && Spree::ZoneMember.column_names.include?('tenant_id')
            zone_ids = Spree::Zone.where(tenant_id: store.id).pluck(:id)
            count = Spree::ZoneMember.where(zone_id: zone_ids, tenant_id: nil).update_all(tenant_id: store.id)
            puts "  - Updated #{count} zone members"
          end
          
          # Users - assign based on their orders
          user_ids = Spree::Order.where(store_id: store.id).pluck(:user_id).compact.uniq
          if user_ids.any? && Spree::User.column_names.include?('tenant_id')
            count = Spree::User.where(id: user_ids, tenant_id: nil).update_all(tenant_id: store.id)
            puts "  - Updated #{count} users"
          end
        end
      end
      
      puts "\n✓ Tenant ID assignment complete!"
      
      if Spree::Store.count == 1
        puts "Single store setup detected - all records assigned to: #{Spree::Store.first.name}"
      else
        puts "Multi-store setup detected - records assigned based on existing associations"
        puts "Please review assignments to ensure they match your business requirements"
      end
    end
    
    desc "Assign existing data to a specific tenant (store)"
    task :assign_to_tenant, [:store_code] => :environment do |t, args|
      store = Spree::Store.find_by(code: args[:store_code])
      
      unless store
        puts "Store with code '#{args[:store_code]}' not found"
        exit 1
      end
      
      puts "Assigning ALL unassigned data to tenant: #{store.name} (#{store.code})"
      puts "WARNING: This will assign ALL records without tenant_id to this store!"
      print "Continue? (y/n): "
      
      response = STDIN.gets.chomp.downcase
      unless response == 'y'
        puts "Aborted"
        exit 0
      end
      
      # Models that need tenant assignment
      models_to_update = [
        Spree::Product,
        Spree::Variant,
        Spree::Taxonomy,
        Spree::Taxon,
        Spree::Order,
        Spree::LineItem,
        Spree::Shipment,
        Spree::Payment,
        Spree::StockLocation,
        Spree::StockItem,
        Spree::StockMovement,
        Spree::Zone,
        Spree::ZoneMember,
        Spree::ShippingMethod,
        Spree::PaymentMethod,
        Spree::Promotion,
        Spree::PromotionRule,
        Spree::PromotionAction,
        Spree::User,
        Spree::Adjustment,
        Spree::ReturnAuthorization,
        Spree::TaxCategory,
        Spree::TaxRate,
        Spree::ShippingCategory,
        Spree::OptionType,
        Spree::OptionValue,
        Spree::Property,
        Spree::ProductProperty,
        Spree::ProductOptionType
      ]
      
      ActiveRecord::Base.transaction do
        models_to_update.each do |model|
          if model.column_names.include?('tenant_id')
            count = model.where(tenant_id: nil).update_all(tenant_id: store.id)
            puts "  Updated #{count} #{model.name} records"
          else
            puts "  Skipped #{model.name} (no tenant_id column)"
          end
        end
        
        # Handle join tables if they have tenant_id
        if ActiveRecord::Base.connection.table_exists?('spree_products_taxons') &&
           ActiveRecord::Base.connection.column_exists?('spree_products_taxons', 'tenant_id')
          count = ActiveRecord::Base.connection.execute(
            "UPDATE spree_products_taxons SET tenant_id = #{store.id} WHERE tenant_id IS NULL"
          ).cmd_tuples
          puts "  Updated #{count} products_taxons records"
        end
      end
      
      puts "Done!"
    end
    
    desc "Create a new tenant (store) with basic setup"
    task :create_tenant, [:name, :code, :url, :mail_from_address] => :environment do |t, args|
      ActiveRecord::Base.transaction do
        store = Spree::Store.create!(
          name: args[:name],
          code: args[:code],
          url: args[:url],
          mail_from_address: args[:mail_from_address] || "noreply@#{args[:url]}",
          default_currency: 'USD',
          supported_currencies: 'USD',
          default: false
        )
        
        puts "Created store: #{store.name} (#{store.code})"
        
        # Set store preferences
        store.set_preference(:registration_disabled, true)
        store.save!
        
        # Create basic configuration within tenant context
        SpreeTcb::MultiTenant.with_tenant(store) do
          # Create default stock location
          Spree::StockLocation.create!(
            name: "#{store.name} Warehouse",
            default: true,
            active: true
          )
          
          # Create default shipping category
          Spree::ShippingCategory.create!(
            name: 'Default'
          )
          
          # Create default zone
          us_zone = Spree::Zone.create!(
            name: 'United States',
            description: 'USA',
            kind: 'country'
          )
          
          # Add US to the zone
          us = Spree::Country.find_by(iso: 'US')
          if us
            us_zone.zone_members.create!(zoneable: us)
          end
          
          puts "  Created default configuration for #{store.name}"
        end
      end
    end
    
    desc "Switch all models to a specific tenant for testing"
    task :switch_to_tenant, [:store_code] => :environment do |t, args|
      store = Spree::Store.find_by(code: args[:store_code])
      
      unless store
        puts "Store with code '#{args[:store_code]}' not found"
        exit 1
      end
      
      SpreeTcb::MultiTenant.current_tenant = store
      puts "Switched to tenant: #{store.name} (#{store.code})"
      puts "All queries will now be scoped to this tenant"
      puts "Run 'SpreeTcb::MultiTenant.clear_tenant!' to clear"
    end
  end
end