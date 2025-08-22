require 'spec_helper'

RSpec.describe SpreeTcb::MultiTenant::TenantController, type: :controller do
  # Create a test controller to test the concern
  controller(ApplicationController) do
    include SpreeTcb::MultiTenant::TenantController
    
    def index
      render json: { 
        tenant_id: current_tenant&.id,
        tenant_code: current_tenant&.code 
      }
    end
  end

  let(:tenant1) { create_tenant(code: 'store1', name: 'Store 1') }
  let(:tenant2) { create_tenant(code: 'store2', name: 'Store 2') }

  before do
    # Setup routes for test controller
    routes.draw { get 'index' => 'anonymous#index' }
  end

  describe '#set_current_tenant' do
    context 'when store exists for domain' do
      before do
        allow(controller).to receive(:current_store).and_return(tenant1)
      end

      it 'sets current tenant from current_store' do
        get :index
        expect(SpreeTcb::MultiTenant.current_tenant).to eq(tenant1)
      end

      it 'makes tenant available via current_tenant helper' do
        get :index
        json = JSON.parse(response.body)
        expect(json['tenant_id']).to eq(tenant1.id)
        expect(json['tenant_code']).to eq('store1')
      end
    end

    context 'when no store exists' do
      before do
        allow(controller).to receive(:current_store).and_return(nil)
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('development'))
      end

      it 'allows request in development' do
        expect { get :index }.not_to raise_error
      end
    end
  end

  describe '#clear_current_tenant' do
    before do
      allow(controller).to receive(:current_store).and_return(tenant1)
    end

    it 'clears tenant after request' do
      get :index
      # After the request completes, tenant should be cleared
      # Note: This happens in after_action, so we need to check after response
      controller.send(:clear_current_tenant)
      expect(SpreeTcb::MultiTenant.current_tenant).to be_nil
    end
  end

  describe '#with_tenant' do
    it 'executes block within tenant context' do
      result = controller.send(:with_tenant, tenant2) do
        SpreeTcb::MultiTenant.current_tenant
      end
      expect(result).to eq(tenant2)
    end
  end

  describe 'admin access control' do
    controller(Spree::Admin::BaseController) do
      include SpreeTcb::MultiTenant::TenantController
      
      def index
        render json: { success: true }
      end
    end

    let(:admin_user) { create(:admin_user) }
    let(:regular_user) { create(:user) }

    before do
      routes.draw { get 'index' => 'spree/admin/base#index' }
      allow(controller).to receive(:current_store).and_return(tenant1)
    end

    context 'with admin user' do
      before do
        allow(controller).to receive(:spree_current_user).and_return(admin_user)
      end

      it 'allows access' do
        get :index
        expect(response).to have_http_status(:success)
      end
    end

    context 'with regular user assigned to tenant' do
      before do
        regular_user.update(tenant_id: tenant1.id)
        allow(controller).to receive(:spree_current_user).and_return(regular_user)
      end

      it 'allows access to assigned tenant' do
        get :index
        expect(response).to have_http_status(:success)
      end
    end

    context 'with regular user assigned to different tenant' do
      before do
        regular_user.update(tenant_id: tenant2.id)
        allow(controller).to receive(:spree_current_user).and_return(regular_user)
        allow(controller).to receive(:main_app).and_return(double(root_path: '/'))
      end

      it 'denies access' do
        get :index
        expect(response).to redirect_to('/')
        expect(flash[:error]).to eq("You don't have access to this store")
      end
    end
  end
end