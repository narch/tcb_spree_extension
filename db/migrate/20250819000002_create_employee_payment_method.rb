class CreateEmployeePaymentMethod < ActiveRecord::Migration[7.0]
  def up
    return if Spree::PaymentMethod.exists?(type: 'SpreeTcb::PaymentMethod::NoPaymentRequired')
    
    Spree::PaymentMethod.create!(
      name: 'Employee Order',
      description: 'No payment required for employee orders',
      type: 'SpreeTcb::PaymentMethod::NoPaymentRequired',
      active: true,
      display_on: 'both',
      auto_capture: true
    )
  end

  def down
    Spree::PaymentMethod.where(type: 'SpreeTcb::PaymentMethod::NoPaymentRequired').destroy_all
  end
end