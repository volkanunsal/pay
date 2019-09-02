module Pay
  module Stripe
    module Webhooks

      class ChargeRefunded < Struct.new(:pay)
        def call(event)
          object = event.data.object
          charge = pay.charge_model.find_by(processor_id: object.id)

          return unless charge.present?

          charge.update(amount_refunded: object.amount_refunded)
          notify_user(charge.owner, charge)
        end

        def notify_user(user, charge)
        end
      end
    end
  end
end
