module SpreeTcb
  module StoreDecorator
    def self.prepended(base)
      base.class_eval do
        # Add registration_disabled preference with default false
        preference :registration_disabled, :boolean, default: false
      end
    end

    def registration_enabled?
      !preferred_registration_disabled
    end

    def registration_disabled?
      preferred_registration_disabled
    end
  end
end

Spree::Store.prepend SpreeTcb::StoreDecorator