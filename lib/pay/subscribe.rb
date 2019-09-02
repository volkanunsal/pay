module Pay
  module Subscribe
    extend ActiveSupport::Concern

    module Subbable
      extend ActiveSupport::Concern
      include Pay::Stripe::Subscription

      # Associations
      belongs_to :owner, class_name: pay.billable_class, foreign_key: :owner_id

      # Validations
      validates :name, :processor, :processor_id, :processor_plan, :quantity,
                presence: true

      # Scopes
      scope :for_name, ->(name) { where(name: name) }
      scope :on_trial, ->{
        where.not(trial_ends_at: nil).where("? < trial_ends_at", Time.zone.now)
      }
      scope :cancelled, ->{ where.not(ends_at: nil) }
      scope :on_grace_period, ->{ cancelled.where("? < ends_at", Time.zone.now) }
      scope :active, ->{ where(ends_at: nil).or(on_grace_period).or(on_trial) }

      attribute :prorate, :boolean, default: true

      def no_prorate
        self.prorate = false
      end

      def skip_trial
        self.trial_ends_at = nil
      end

      def on_trial?
        trial_ends_at? && Time.zone.now < trial_ends_at
      end

      def cancelled?
        ends_at?
      end

      def on_grace_period?
        cancelled? && Time.zone.now < ends_at
      end

      def active?
        ends_at.nil? || on_grace_period? || on_trial?
      end

      def cancel
        stripe_cancel
      end

      def cancel_now!
        stripe_cancel_now!
      end

      def resume
        unless on_grace_period?
          raise StandardError,
                'You can only resume subscriptions within their grace period.'
        end

        stripe_resume

        update(ends_at: nil)
        self
      end

      def swap(plan)
        stripe_swap(plan)
        update(processor_plan: plan, ends_at: nil)
      end

      def processor_subscription
        owner.processor_subscription(processor_id)
      end
    end

    # Adds the subscription methods and fields to the host class.
    #
    # Usage:
    #
    #   class Subscription < ApplicationRecord
    #     include Pay::Subscribe
    #
    #     billable 'User'
    #   end
    #
    class_methods do
      def billable(klass_name)
        klass = klass_name.kind_of?(String) ? klass_name.constantize : klass_name
        self.pay = klass.pay

        include Subbable
      end
    end
  end
end
