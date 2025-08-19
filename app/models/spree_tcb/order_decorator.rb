module SpreeTcb
  module OrderDecorator
    def self.prepended(base)
      base.class_eval do
        # Skip payment confirmation for employee orders
        def confirmation_required?
          false
        end

        # Automatically select the employee payment method if only one exists
        def available_payment_methods
          @available_payment_methods ||= begin
            methods = Spree::PaymentMethod.active.available_on_front_end
            employee_method = methods.find { |m| m.type == 'SpreeTcb::PaymentMethod::NoPaymentRequired' }
            employee_method ? [employee_method] : methods
          end
        end
      end
    end

    # Optional: Add employee tracking
    def employee_order?
      payments.joins(:payment_method).where(spree_payment_methods: { type: 'SpreeTcb::PaymentMethod::NoPaymentRequired' }).exists?
    end
  end
end

Spree::Order.prepend SpreeTcb::OrderDecorator