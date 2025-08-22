require 'spec_helper'

RSpec.describe SpreeTcb::MultiTenant do
  let(:tenant1) { create_tenant(code: 'store1', name: 'Store 1') }
  let(:tenant2) { create_tenant(code: 'store2', name: 'Store 2') }

  describe '.current_tenant' do
    it 'returns nil by default' do
      expect(described_class.current_tenant).to be_nil
    end

    it 'returns the set tenant' do
      described_class.current_tenant = tenant1
      expect(described_class.current_tenant).to eq(tenant1)
    end
  end

  describe '.current_tenant=' do
    it 'sets the current tenant' do
      described_class.current_tenant = tenant1
      expect(described_class.current_tenant).to eq(tenant1)
    end
  end

  describe '.clear_tenant!' do
    it 'clears the current tenant' do
      described_class.current_tenant = tenant1
      described_class.clear_tenant!
      expect(described_class.current_tenant).to be_nil
    end
  end

  describe '.with_tenant' do
    it 'executes block within tenant context' do
      expect(described_class.current_tenant).to be_nil
      
      described_class.with_tenant(tenant1) do
        expect(described_class.current_tenant).to eq(tenant1)
      end
      
      expect(described_class.current_tenant).to be_nil
    end

    it 'restores previous tenant after block' do
      described_class.current_tenant = tenant1
      
      described_class.with_tenant(tenant2) do
        expect(described_class.current_tenant).to eq(tenant2)
      end
      
      expect(described_class.current_tenant).to eq(tenant1)
    end

    it 'restores tenant even if block raises error' do
      described_class.current_tenant = tenant1
      
      expect {
        described_class.with_tenant(tenant2) do
          expect(described_class.current_tenant).to eq(tenant2)
          raise 'Test error'
        end
      }.to raise_error('Test error')
      
      expect(described_class.current_tenant).to eq(tenant1)
    end
  end

  describe '.tenanted_models' do
    it 'returns array of model names' do
      expect(described_class.tenanted_models).to be_an(Array)
      expect(described_class.tenanted_models).to include('Spree::Product')
      expect(described_class.tenanted_models).to include('Spree::Order')
    end
  end

  describe '.shared_models' do
    it 'returns array of shared model names' do
      expect(described_class.shared_models).to be_an(Array)
      expect(described_class.shared_models).to include('Spree::Country')
      expect(described_class.shared_models).to include('Spree::State')
      expect(described_class.shared_models).to include('Spree::Store')
    end

    it 'does not include Store in tenanted_models' do
      expect(described_class.tenanted_models).not_to include('Spree::Store')
    end
  end

  describe 'thread safety' do
    it 'maintains separate tenant per thread' do
      tenant_in_thread = nil
      
      described_class.current_tenant = tenant1
      
      thread = Thread.new do
        described_class.current_tenant = tenant2
        tenant_in_thread = described_class.current_tenant
      end
      thread.join
      
      expect(described_class.current_tenant).to eq(tenant1)
      expect(tenant_in_thread).to eq(tenant2)
    end
  end
end