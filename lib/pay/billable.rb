module Pay
  module Billable
    extend ActiveSupport::Concern

    module BillableMixin
      extend ActiveSupport::Concern
      include Pay::Stripe::Billable

      included do
        has_many :charges, class_name: pay.chargeable_class, foreign_key: :owner_id, inverse_of: :owner
        has_many :subscriptions, class_name: pay.subscription_class, foreign_key: :owner_id, inverse_of: :owner

        attribute :plan, :string
        attribute :quantity, :integer
        attribute :card_token, :string
      end

      def customer
        raise Pay::Error, "Email is required to create a customer" if email.nil?

        customer = stripe_customer
        update_card(card_token) if card_token.present?
        customer
      end

      def customer_name
        [try(:first_name), try(:last_name)].compact.join(" ")
      end

      def charge(amount_in_cents, options = {})
        # TODO: maybe create a Charge object in the db and return it from here.
        # Currently, it returns a Stripe::Charge object. But I'm not sure if this
        # will be necessary...
        create_stripe_charge(amount_in_cents, options)
      end

      def subscribe(name: 'default', plan: 'default', **options)
        create_stripe_subscription(name, plan, options)
      end

      def update_card(token)
        customer if processor_id.nil?
        update_stripe_card(token)
      end

      def on_trial?(name: 'default', plan: nil)
        return true if default_generic_trial?(name, plan)

        sub = subscription(name: name)
        return sub && sub.on_trial? if plan.nil?

        sub && sub.on_trial? && sub.processor_plan == plan
      end

      def on_generic_trial?
        trial_ends_at? && trial_ends_at > Time.zone.now
      end

      def processor_subscription(subscription_id)
        stripe_subscription(subscription_id)
      end

      def subscribed?(name: 'default', processor_plan: nil)
        subscription = subscription(name: name)

        return false if subscription.nil?
        return subscription.active? if processor_plan.nil?

        subscription.active? && subscription.processor_plan == processor_plan
      end

      def on_trial_or_subscribed?(name: 'default', processor_plan: nil)
        on_trial?(name: name, plan: processor_plan) ||
          subscribed?(name: name, processor_plan: processor_plan)
      end

      def subscription(name: 'default')
        subscriptions.for_name(name).last
      end

      def invoice!
        stripe_invoice!
      end

      def upcoming_invoice
        stripe_upcoming_invoice
      end

      private

      def create_subscription(subscription, name, plan, qty = 1)
        subscriptions.create!(
          name: name || 'default',
          processor_id: subscription.id,
          processor_plan: plan,
          trial_ends_at: stripe_trial_end_date(subscription),
          quantity: qty,
          ends_at: nil
        )
      end

      def default_generic_trial?(name, plan)
        # Generic trials don't have plans or custom names
        plan.nil? && name == 'default' && on_generic_trial?
      end
    end
  end

  # Adds the billable methods and fields to the host class.
  #
  # Usage:
  #
  #   class User < ApplicationRecord
  #     include Pay::Billable
  #
  #     pay_config  charge_class: 'Charge',
  #                 subscription_class: 'Membership',
  #                 subscription_plan_class: 'Plan',
  #                 setup_class: 'PaymentSetup'
  #   end
  #
  class_methods do
    def pay_config(config = {})
      include BillableMixin
      config.symbolize_keys!

      # Validate config
      pay = Pay::Config.new(config.merge(user_class: self.name))

      # Run the setup class with the usable instance.
      setup_class = config.fetch(:setup_class) { 'Pay::Stripe::Setup' }.constantize
      setup_class.call(pay)

      class_attribute :pay
      self.pay = pay
    end
  end
end
