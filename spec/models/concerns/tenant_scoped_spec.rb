require 'spec_helper'

RSpec.describe SpreeTcb::MultiTenant::TenantScoped, without_global_store: true do
  let(:tenant1) { create_tenant(code: 'store1', name: 'Store 1') }
  let(:tenant2) { create_tenant(code: 'store2', name: 'Store 2') }

  describe 'automatic tenant scoping' do
    context 'with Product model' do
      it 'automatically assigns tenant_id on create' do
        with_tenant(tenant1) do
          product = Spree::Product.create!(
            name: 'Test Product',
            price: 10.00,
            shipping_category: Spree::ShippingCategory.first_or_create(name: 'Default')
          )
          expect(product.tenant_id).to eq(tenant1.id)
        end
      end

      it 'scopes queries to current tenant' do
        # Create products for different tenants
        product1 = nil
        product2 = nil
        
        with_tenant(tenant1) do
          product1 = Spree::Product.create!(
            name: 'Tenant 1 Product',
            price: 10.00,
            shipping_category: Spree::ShippingCategory.first_or_create(name: 'Default')
          )
        end

        with_tenant(tenant2) do
          product2 = Spree::Product.create!(
            name: 'Tenant 2 Product',
            price: 20.00,
            shipping_category: Spree::ShippingCategory.first_or_create(name: 'Default')
          )
        end

        # Verify scoping
        with_tenant(tenant1) do
          products = Spree::Product.all
          expect(products).to include(product1)
          expect(products).not_to include(product2)
        end

        with_tenant(tenant2) do
          products = Spree::Product.all
          expect(products).to include(product2)
          expect(products).not_to include(product1)
        end
      end

      it 'prevents cross-tenant access' do
        product = nil
        
        with_tenant(tenant1) do
          product = Spree::Product.create!(
            name: 'Tenant 1 Product',
            price: 10.00,
            shipping_category: Spree::ShippingCategory.first_or_create(name: 'Default')
          )
        end

        with_tenant(tenant2) do
          expect(Spree::Product.find_by(id: product.id)).to be_nil
        end
      end
    end
  end

  describe '.unscoped_all' do
    it 'returns all records across tenants' do
      product1 = nil
      product2 = nil
      
      with_tenant(tenant1) do
        product1 = Spree::Product.create!(
          name: 'Tenant 1 Product',
          price: 10.00,
          shipping_category: Spree::ShippingCategory.first_or_create(name: 'Default')
        )
      end

      with_tenant(tenant2) do
        product2 = Spree::Product.create!(
          name: 'Tenant 2 Product',
          price: 20.00,
          shipping_category: Spree::ShippingCategory.first_or_create(name: 'Default')
        )
      end

      all_products = Spree::Product.unscoped_all
      expect(all_products).to include(product1, product2)
    end
  end

  describe '.for_tenant' do
    it 'returns records for specific tenant' do
      product1 = nil
      product2 = nil
      
      with_tenant(tenant1) do
        product1 = Spree::Product.create!(
          name: 'Tenant 1 Product',
          price: 10.00,
          shipping_category: Spree::ShippingCategory.first_or_create(name: 'Default')
        )
      end

      with_tenant(tenant2) do
        product2 = Spree::Product.create!(
          name: 'Tenant 2 Product',
          price: 20.00,
          shipping_category: Spree::ShippingCategory.first_or_create(name: 'Default')
        )
      end

      tenant1_products = Spree::Product.for_tenant(tenant1)
      expect(tenant1_products).to include(product1)
      expect(tenant1_products).not_to include(product2)
    end
  end

  describe 'tenant validation' do
    it 'prevents changing tenant_id to another tenant' do
      product = nil
      
      with_tenant(tenant1) do
        product = Spree::Product.create!(
          name: 'Test Product',
          price: 10.00,
          shipping_category: Spree::ShippingCategory.first_or_create(name: 'Default')
        )
      end

      with_tenant(tenant1) do
        product.tenant_id = tenant2.id
        expect(product).not_to be_valid
        expect(product.errors[:tenant_id]).to include('does not match current tenant')
      end
    end
  end

  describe 'unique constraints' do
    it 'allows same slug in different tenants' do
      with_tenant(tenant1) do
        Spree::Product.create!(
          name: 'Same Product',
          slug: 'same-product',
          price: 10.00,
          shipping_category: Spree::ShippingCategory.first_or_create(name: 'Default')
        )
      end

      with_tenant(tenant2) do
        product = Spree::Product.create!(
          name: 'Same Product',
          slug: 'same-product',
          price: 20.00,
          shipping_category: Spree::ShippingCategory.first_or_create(name: 'Default')
        )
        expect(product).to be_persisted
      end
    end

    it 'prevents duplicate slugs within same tenant' do
      with_tenant(tenant1) do
        Spree::Product.create!(
          name: 'Product 1',
          slug: 'same-slug',
          price: 10.00,
          shipping_category: Spree::ShippingCategory.first_or_create(name: 'Default')
        )

        duplicate = Spree::Product.new(
          name: 'Product 2',
          slug: 'same-slug',
          price: 20.00,
          shipping_category: Spree::ShippingCategory.first_or_create(name: 'Default')
        )
        
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:slug]).to be_present
      end
    end
  end
end