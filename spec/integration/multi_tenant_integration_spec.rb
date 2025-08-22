require 'spec_helper'

RSpec.describe 'Multi-Tenant Integration' do
  let(:tenant1) { create_tenant(code: 'store1', name: 'Store 1') }
  let(:tenant2) { create_tenant(code: 'store2', name: 'Store 2') }

  describe 'complete tenant isolation' do
    it 'maintains complete data isolation between tenants' do
      # Setup data for tenant1
      tenant1_data = {}
      with_tenant(tenant1) do
        # Create taxonomy
        taxonomy = Spree::Taxonomy.create!(name: 'Categories')
        taxon = taxonomy.root.children.create!(name: 'Electronics', taxonomy: taxonomy)
        
        # Create product
        product = Spree::Product.create!(
          name: 'Laptop',
          price: 999.99,
          shipping_category: Spree::ShippingCategory.first_or_create(name: 'Default'),
          taxons: [taxon]
        )
        
        # Create stock location
        stock_location = Spree::StockLocation.create!(
          name: 'Main Warehouse',
          default: true
        )
        
        # Set stock
        stock_item = product.stock_items.find_by(stock_location: stock_location)
        stock_item.update!(count_on_hand: 100) if stock_item
        
        # Create zone
        zone = Spree::Zone.create!(
          name: 'North America',
          description: 'US and Canada'
        )
        
        # Create shipping method
        shipping_method = Spree::ShippingMethod.create!(
          name: 'Standard Shipping',
          display_on: 'both',
          zones: [zone],
          shipping_categories: [Spree::ShippingCategory.first]
        )
        
        # Create payment method
        payment_method = Spree::PaymentMethod.create!(
          name: 'Credit Card',
          type: 'Spree::PaymentMethod::Check',
          active: true,
          display_on: 'both'
        )
        
        # Create order
        order = Spree::Order.create!(
          email: 'customer@store1.com',
          store: tenant1
        )
        
        # Add line item
        line_item = order.line_items.create!(
          variant: product.master,
          quantity: 2,
          price: product.price
        )
        
        tenant1_data = {
          product_count: Spree::Product.count,
          taxonomy_count: Spree::Taxonomy.count,
          taxon_count: Spree::Taxon.count,
          order_count: Spree::Order.count,
          line_item_count: Spree::LineItem.count,
          zone_count: Spree::Zone.count,
          shipping_method_count: Spree::ShippingMethod.count,
          payment_method_count: Spree::PaymentMethod.count,
          stock_location_count: Spree::StockLocation.count
        }
      end

      # Setup data for tenant2
      tenant2_data = {}
      with_tenant(tenant2) do
        # Create different product
        product = Spree::Product.create!(
          name: 'Phone',
          price: 599.99,
          shipping_category: Spree::ShippingCategory.first_or_create(name: 'Default')
        )
        
        # Create order
        order = Spree::Order.create!(
          email: 'customer@store2.com',
          store: tenant2
        )
        
        tenant2_data = {
          product_count: Spree::Product.count,
          taxonomy_count: Spree::Taxonomy.count,
          taxon_count: Spree::Taxon.count,
          order_count: Spree::Order.count,
          line_item_count: Spree::LineItem.count,
          zone_count: Spree::Zone.count,
          shipping_method_count: Spree::ShippingMethod.count,
          payment_method_count: Spree::PaymentMethod.count,
          stock_location_count: Spree::StockLocation.count
        }
      end

      # Verify isolation
      expect(tenant1_data[:product_count]).to eq(1)
      expect(tenant2_data[:product_count]).to eq(1)
      
      expect(tenant1_data[:order_count]).to eq(1)
      expect(tenant2_data[:order_count]).to eq(1)
      
      expect(tenant1_data[:line_item_count]).to eq(1)
      expect(tenant2_data[:line_item_count]).to eq(0)
      
      # Verify no cross-contamination
      with_tenant(tenant1) do
        expect(Spree::Product.find_by(name: 'Phone')).to be_nil
        expect(Spree::Order.find_by(email: 'customer@store2.com')).to be_nil
      end

      with_tenant(tenant2) do
        expect(Spree::Product.find_by(name: 'Laptop')).to be_nil
        expect(Spree::Order.find_by(email: 'customer@store1.com')).to be_nil
      end
    end
  end

  describe 'shared resources' do
    it 'shares countries and states across tenants' do
      # Countries and states should be available to all tenants
      country = Spree::Country.find_or_create_by!(
        iso: 'US',
        name: 'United States',
        iso3: 'USA',
        numcode: 840
      )
      
      state = Spree::State.find_or_create_by!(
        name: 'California',
        abbr: 'CA',
        country: country
      )

      with_tenant(tenant1) do
        # Should be able to access shared resources
        expect(Spree::Country.find_by(iso: 'US')).to eq(country)
        expect(Spree::State.find_by(abbr: 'CA')).to eq(state)
      end

      with_tenant(tenant2) do
        # Same resources available
        expect(Spree::Country.find_by(iso: 'US')).to eq(country)
        expect(Spree::State.find_by(abbr: 'CA')).to eq(state)
      end
    end
  end

  describe 'order workflow' do
    it 'completes order workflow within tenant context' do
      with_tenant(tenant1) do
        # Create necessary setup
        shipping_category = Spree::ShippingCategory.first_or_create(name: 'Default')
        
        product = Spree::Product.create!(
          name: 'Test Product',
          price: 50.00,
          shipping_category: shipping_category
        )
        
        stock_location = Spree::StockLocation.create!(
          name: 'Warehouse',
          default: true,
          active: true
        )
        
        # Ensure stock
        stock_item = product.master.stock_items.find_or_create_by!(
          stock_location: stock_location
        )
        stock_item.update!(count_on_hand: 10)
        
        # Create order
        order = Spree::Order.create!(
          email: 'test@example.com',
          store: tenant1
        )
        
        # Add items
        line_item = order.line_items.create!(
          variant: product.master,
          quantity: 1,
          price: product.price
        )
        
        # Verify all components have correct tenant
        expect(product.tenant_id).to eq(tenant1.id)
        expect(order.tenant_id).to eq(tenant1.id)
        expect(line_item.tenant_id).to eq(tenant1.id)
        expect(stock_location.tenant_id).to eq(tenant1.id)
        
        # Update totals
        order.update_totals
        expect(order.total).to eq(50.00)
      end

      # Verify isolation
      with_tenant(tenant2) do
        expect(Spree::Order.find_by(email: 'test@example.com')).to be_nil
        expect(Spree::Product.find_by(name: 'Test Product')).to be_nil
      end
    end
  end

  describe 'promotion isolation' do
    it 'isolates promotions between tenants' do
      promo1 = nil
      promo2 = nil
      
      with_tenant(tenant1) do
        promo1 = Spree::Promotion.create!(
          name: 'Store 1 Sale',
          code: 'SALE20',
          description: '20% off everything'
        )
      end

      with_tenant(tenant2) do
        promo2 = Spree::Promotion.create!(
          name: 'Store 2 Special',
          code: 'SALE20', # Same code allowed
          description: '10% off'
        )
        
        # Should only see tenant2's promotion
        expect(Spree::Promotion.all).to include(promo2)
        expect(Spree::Promotion.all).not_to include(promo1)
        expect(Spree::Promotion.find_by(code: 'SALE20')).to eq(promo2)
      end
    end
  end
end