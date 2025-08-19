module SpreeTcb
  module PaymentMethod
    class NoPaymentRequired < Spree::PaymentMethod
      def payment_source_class
        nil
      end

      def source_required?
        false
      end

      def auto_capture?
        true
      end

      def supports?(source)
        true
      end

      def actions
        %w[capture void]
      end

      def can_capture?(payment)
        payment.pending? || payment.checkout?
      end

      def can_void?(payment)
        !payment.void?
      end

      def capture(*args)
        ActiveMerchant::Billing::Response.new(
          true,
          "Employee order processed",
          {},
          authorization: "EMP-#{Time.current.to_i}"
        )
      end

      def void(*args)
        ActiveMerchant::Billing::Response.new(
          true,
          "Employee order voided",
          {},
          {}
        )
      end

      def try_void(payment)
        void
      end
    end
  end
end