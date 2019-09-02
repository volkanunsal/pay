require 'stripe_event'
Dir[File.join(__dir__, 'webhooks', '**', '*.rb')].each { |file| require file }

module Pay::Stripe
  class Setup
    def call(pay)
      StripeEvent.configure do |events|
        # Listen to the charge event to make sure we get non-subscription
        # purchases as well. Invoice is only for subscriptions and manual creation
        # so it does not include individual charges.
        events.subscribe 'charge.succeeded', Webhooks::ChargeSucceeded.new(pay)
        events.subscribe 'charge.refunded', Webhooks::ChargeRefunded.new(pay)

        # Warn user of upcoming charges for their subscription. This is handy for
        # notifying annual users their subscription will renew shortly.
        # This probably should be ignored for monthly subscriptions.
        events.subscribe 'invoice.upcoming', Webhooks::SubscriptionRenewing.new(pay)

        # If a subscription is manually created on Stripe, we want to sync
        events.subscribe 'customer.subscription.created', Webhooks::SubscriptionCreated.new(pay)

        # If the plan, quantity, or trial ending date is updated on Stripe, we want to sync
        events.subscribe 'customer.subscription.updated', Webhooks::SubscriptionUpdated.new(pay)

        # When a customers subscription is canceled, we want to update our records
        events.subscribe 'customer.subscription.deleted', Webhooks::SubscriptionDeleted.new(pay)

        # Monitor changes for customer's default card changing
        events.subscribe 'customer.updated', Webhooks::CustomerUpdated.new(pay)

        # If a customer was deleted in Stripe, their subscriptions should be cancelled
        events.subscribe 'customer.deleted', Webhooks::CustomerDeleted.new(pay)

        # If a customer's payment source was deleted in Stripe, we should update as well
        events.subscribe 'customer.source.deleted', Webhooks::SourceDeleted.new(pay)
      end
    end
  end
end