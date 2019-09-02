module Pay
  module Stripe
    module Webhooks

      class SubscriptionCreated < Struct.new(:pay)
        def call(event)
          object = event.data.object

          # We may already have the subscription in the database, so we can update that record
          subscription = pay.subscription_model.find_by(processor_id: object.id)

          if subscription.nil?
            # The customer should already be in the database
            owner = pay.user_model.find_by(processor_id: object.customer)

            Rails.logger.error("[Pay] Unable to find #{pay.user_model} with processor_id: '#{object.customer}'")
            return if owner.nil?

            subscription = pay.subscription_model.new(owner: owner)
          end

          subscription.quantity       = object.quantity
          subscription.processor_plan = object.plan.id
          subscription.trial_ends_at  = Time.at(object.trial_end) if object.trial_end.present?

          # If user was on trial, their subscription ends at the end of the trial
          if object.cancel_at_period_end && subscription.on_trial?
            subscription.ends_at = subscription.trial_ends_at

          # User wasn't on trial, so subscription ends at period end
          elsif object.cancel_at_period_end
            subscription.ends_at = Time.at(object.current_period_end)

          # Subscription isn't marked to cancel at period end
          else
            subscription.ends_at = nil
          end

          subscription.save!
        end
      end

    end
  end
end

