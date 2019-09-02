module Pay
  module Stripe
    module Webhooks

      class CustomerUpdated < Struct.new(:pay)
        def call(event)
          object = event.data.object
          user = pay.user_model.find_by(processor_id: object.id)

          # Couldn't find user, we can skip
          return unless user.present?

          user.sync_card_from_stripe
        end
      end

    end
  end
end
