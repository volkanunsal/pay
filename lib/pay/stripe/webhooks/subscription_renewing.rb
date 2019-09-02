module Pay
  module Stripe
    module Webhooks

      class SubscriptionRenewing < Struct.new(:pay)
        def call(event)
          # Event is of type "invoice" see:
          # https://stripe.com/docs/api/invoices/object
          subscription = pay.subscription_model.find_by(
            processor_id: event.data.object.subscription
          )
          notify_user(subscription.owner, subscription) if subscription.present?
        end

        def notify_user(user, subscription)
        end
      end

    end
  end
end
