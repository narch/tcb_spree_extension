class AddRegistrationDisabledToStores < ActiveRecord::Migration[7.0]
  def up
    # Set registration_disabled to true for all existing stores
    # This makes it opt-in for employee-only stores
    Spree::Store.find_each do |store|
      store.set_preference(:registration_disabled, true)
      store.save!
    end
  end

  def down
    # Remove the preference on rollback
    Spree::Store.find_each do |store|
      store.preferences.delete(:registration_disabled)
      store.save!
    end
  end
end