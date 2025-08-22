require 'spec_helper'

RSpec.describe Spree::Store do
  let(:store) { create_tenant(code: 'test', name: 'Test Store') }

  describe 'preferences' do
    describe '#registration_disabled' do
      it 'defaults to false' do
        expect(store.preferred_registration_disabled).to be false
      end

      it 'can be set to true' do
        store.set_preference(:registration_disabled, true)
        store.save!
        expect(store.preferred_registration_disabled).to be true
      end
    end

    describe '#registration_enabled?' do
      it 'returns true when registration is not disabled' do
        store.set_preference(:registration_disabled, false)
        expect(store.registration_enabled?).to be true
      end

      it 'returns false when registration is disabled' do
        store.set_preference(:registration_disabled, true)
        expect(store.registration_disabled?).to be true
        expect(store.registration_enabled?).to be false
      end
    end
  end

  describe 'tenant associations' do
    let(:other_store) { create_tenant(code: 'other', name: 'Other Store') }

    describe '#products' do
      it 'returns products for this tenant' do
        product = nil
        with_tenant(store) do
          product = Spree::Product.create!(
            name: 'Test Product',
            price: 10.00,
            shipping_category: Spree::ShippingCategory.first_or_create(name: 'Default')
          )
        end

        expect(store.products).to include(product)
        expect(other_store.products).not_to include(product)
      end
    end

    describe '#orders' do
      it 'returns orders for this tenant' do
        order = nil
        with_tenant(store) do
          order = Spree::Order.create!(
            email: 'test@example.com',
            store: store
          )
        end

        expect(store.orders).to include(order)
        expect(other_store.orders).not_to include(order)
      end
    end

    describe '#stock_locations' do
      it 'returns stock locations for this tenant' do
        location = nil
        with_tenant(store) do
          location = Spree::StockLocation.create!(
            name: 'Test Warehouse',
            default: true
          )
        end

        expect(store.stock_locations).to include(location)
        expect(other_store.stock_locations).not_to include(location)
      end
    end

    describe '#zones' do
      it 'returns zones for this tenant' do
        zone = nil
        with_tenant(store) do
          zone = Spree::Zone.create!(
            name: 'Test Zone',
            description: 'Test'
          )
        end

        expect(store.zones).to include(zone)
        expect(other_store.zones).not_to include(zone)
      end
    end

    describe '#users' do
      it 'returns users for this tenant' do
        user = nil
        with_tenant(store) do
          user = Spree::User.create!(
            email: 'user@example.com',
            password: 'password123'
          )
        end

        expect(store.users).to include(user)
        expect(other_store.users).not_to include(user)
      end

      it 'nullifies user tenant_id on store destroy' do
        user = nil
        with_tenant(store) do
          user = Spree::User.create!(
            email: 'user@example.com',
            password: 'password123'
          )
        end

        expect(user.tenant_id).to eq(store.id)
        
        store.destroy
        user.reload
        
        expect(user.tenant_id).to be_nil
      end
    end
  end

  describe 'destroying a store' do
    it 'destroys dependent tenant-scoped records' do
      with_tenant(store) do
        Spree::Product.create!(
          name: 'Test Product',
          price: 10.00,
          shipping_category: Spree::ShippingCategory.first_or_create(name: 'Default')
        )
        
        Spree::Order.create!(
          email: 'test@example.com',
          store: store
        )
      end

      expect { store.destroy }.to change { Spree::Product.unscoped_all.count }.by(-1)
        .and change { Spree::Order.unscoped_all.count }.by(-1)
    end
  end
end