module Pay
  module Charge
    extend ActiveSupport::Concern

    module Chargeable
      extend ActiveSupport::Concern
      include Pay::Stripe::Charge, Pay::Receipts

      # Associations
      belongs_to :owner, class_name: pay.billable_class, foreign_key: :owner_id

      # Scopes
      scope :sorted, -> { order(created_at: :desc) }
      default_scope -> { sorted }

      # Validations
      validates :amount, :processor_id, :card_type, presence: true

      def processor_charge
        stripe_charge
      end

      def refund!(refund_amount = nil)
        refund_amount ||= amount
        stripe_refund!(refund_amount)
      end

      def charged_to
        "#{card_type} (**** **** **** #{card_last4})"
      end
    end

    # Adds the charge methods and fields to the host class.
    #
    # Usage:
    #
    #   class Charge < ApplicationRecord
    #     include Pay::Charge
    #
    #     billable 'User'
    #   end
    #
    class_methods do
      def billable(klass_name)
        klass = klass_name.kind_of?(String) ? klass_name.constantize : klass_name

        class_attribute :pay
        self.pay = klass.pay

        include Chargeable
      end
    end
  end
end
