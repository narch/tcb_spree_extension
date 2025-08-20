module SpreeTcb
  module UserRegistrationsControllerDecorator
    def self.prepended(base)
      base.before_action :check_registration_enabled
    end

    private

    def check_registration_enabled
      if current_store&.registration_disabled?
        flash[:error] = "Registration is disabled. Please contact your administrator for account access."
        redirect_to spree.login_path and return
      end
    end
  end
end

# This will be loaded when the controller is defined
::Spree::UserRegistrationsController.prepend SpreeTcb::UserRegistrationsControllerDecorator if defined?(::Spree::UserRegistrationsController)