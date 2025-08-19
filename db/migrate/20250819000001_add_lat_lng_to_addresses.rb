class AddLatLngToAddresses < ActiveRecord::Migration[7.0]
  def change
    unless column_exists?(:spree_addresses, :latitude)
      add_column :spree_addresses, :latitude, :float
    end
    
    unless column_exists?(:spree_addresses, :longitude)
      add_column :spree_addresses, :longitude, :float
    end

    unless column_exists?(:spree_stock_locations, :latitude)
      add_column :spree_stock_locations, :latitude, :float
    end
    
    unless column_exists?(:spree_stock_locations, :longitude)
      add_column :spree_stock_locations, :longitude, :float
    end
  end
end