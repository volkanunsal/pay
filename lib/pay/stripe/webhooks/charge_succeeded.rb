module Pay
  module Stripe
    module Webhooks

      class ChargeSucceeded < Struct.new(:pay)
        def call(event)
          object = event.data.object
          user   = pay.user_model.find_by(
            processor_id: object.customer
          )

          return unless user.present?
          return if user.charges.where(processor_id: object.id).any?

          charge = create_charge(user, object)
          notify_user(user, charge)
          charge
        end

        def create_charge(user, object)
          charge = user.charges.find_or_initialize_by(
            processor:      :stripe,
            processor_id:   object.id,
          )

          charge.update(
            amount:         object.amount,
            card_last4:     object.source.last4,
            card_type:      object.source.brand,
            card_exp_month: object.source.exp_month,
            card_exp_year:  object.source.exp_year,
            created_at:     Time.zone.at(object.created)
          )

          charge
        end

        def notify_user(user, charge)
        end
      end
    end
  end
end
