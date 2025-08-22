require 'spec_helper'

RSpec.describe 'Order Multi-Tenancy' do
  let(:tenant1) { create_tenant(code: 'store1', name: 'Store 1') }
  let(:tenant2) { create_tenant(code: 'store2', name: 'Store 2') }

  describe 'order isolation' do
    it 'isolates orders between tenants' do
      order1 = nil
      order2 = nil
      
      with_tenant(tenant1) do
        order1 = Spree::Order.create!(
          email: 'customer1@example.com',
          store: tenant1
        )
      end

      with_tenant(tenant2) do
        order2 = Spree::Order.create!(
          email: 'customer2@example.com',
          store: tenant2
        )
        
        # Should not see tenant1's order
        expect(Spree::Order.all).to include(order2)
        expect(Spree::Order.all).not_to include(order1)
      end
    end

    it 'allows same order number in different tenants' do
      with_tenant(tenant1) do
        Spree::Order.create!(
          number: 'R123456789',
          email: 'customer1@example.com',
          store: tenant1
        )
      end

      with_tenant(tenant2) do
        order = Spree::Order.create!(
          number: 'R123456789',
          email: 'customer2@example.com',
          store: tenant2
        )
        expect(order).to be_persisted
      end
    end

    it 'prevents duplicate order numbers within same tenant' do
      with_tenant(tenant1) do
        Spree::Order.create!(
          number: 'R123456789',
          email: 'customer1@example.com',
          store: tenant1
        )

        duplicate = Spree::Order.new(
          number: 'R123456789',
          email: 'customer2@example.com',
          store: tenant1
        )
        
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:number]).to be_present
      end
    end
  end

  describe 'line items' do
    it 'isolates line items with orders' do
      order1 = nil
      order2 = nil
      
      with_tenant(tenant1) do
        order1 = Spree::Order.create!(
          email: 'customer1@example.com',
          store: tenant1
        )
        
        product = Spree::Product.create!(
          name: 'Tenant 1 Product',
          price: 10.00,
          shipping_category: Spree::ShippingCategory.first_or_create(name: 'Default')
        )
        
        variant = product.master
        line_item = order1.line_items.create!(
          variant: variant,
          quantity: 1,
          price: variant.price
        )
        
        expect(line_item.tenant_id).to eq(tenant1.id)
      end

      with_tenant(tenant2) do
        # Should not see tenant1's line items
        expect(Spree::LineItem.all).to be_empty
      end
    end
  end

  describe 'shipments' do
    it 'isolates shipments between tenants' do
      with_tenant(tenant1) do
        order = Spree::Order.create!(
          email: 'customer1@example.com',
          store: tenant1
        )
        
        stock_location = Spree::StockLocation.create!(
          name: 'Tenant 1 Warehouse',
          default: true
        )
        
        shipment = order.shipments.create!(
          stock_location: stock_location,
          state: 'pending'
        )
        
        expect(shipment.tenant_id).to eq(tenant1.id)
      end

      with_tenant(tenant2) do
        expect(Spree::Shipment.all).to be_empty
      end
    end
  end

  describe 'payments' do
    it 'isolates payments between tenants' do
      with_tenant(tenant1) do
        order = Spree::Order.create!(
          email: 'customer1@example.com',
          store: tenant1
        )
        
        payment_method = Spree::PaymentMethod.create!(
          name: 'Test Payment',
          type: 'Spree::PaymentMethod::Check',
          active: true
        )
        
        payment = order.payments.create!(
          payment_method: payment_method,
          amount: 100.00,
          state: 'pending'
        )
        
        expect(payment.tenant_id).to eq(tenant1.id)
      end

      with_tenant(tenant2) do
        expect(Spree::Payment.all).to be_empty
      end
    end
  end
end