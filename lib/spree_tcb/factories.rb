FactoryBot.define do
  # Define your Spree extensions Factories within this file to enable applications, and other extensions to use and override them.
  #
  # Example adding this to your spec_helper will load these Factories for use:
  # require 'spree_tcb/factories'
  
  factory :tenant_store, class: 'Spree::Store' do
    sequence(:code) { |n| "store_#{n}" }
    sequence(:name) { |n| "Store #{n}" }
    sequence(:url) { |n| "store#{n}.example.com" }
    mail_from_address { "noreply@#{url}" }
    default_currency { 'USD' }
    supported_currencies { 'USD' }
    default { false }
    
    trait :with_disabled_registration do
      after(:create) do |store|
        store.set_preference(:registration_disabled, true)
        store.save!
      end
    end
  end

  # Factory for creating products with tenant
  factory :tenant_product, parent: :base_product, class: 'Spree::Product' do
    transient do
      tenant { Spree::Store.first || create(:tenant_store) }
    end

    after(:build) do |product, evaluator|
      product.tenant_id = evaluator.tenant.id if evaluator.tenant
    end
  end

  # Factory for creating orders with tenant
  factory :tenant_order, parent: :order, class: 'Spree::Order' do
    transient do
      tenant { Spree::Store.first || create(:tenant_store) }
    end

    after(:build) do |order, evaluator|
      order.tenant_id = evaluator.tenant.id if evaluator.tenant
      order.store = evaluator.tenant if evaluator.tenant
    end
  end
end
