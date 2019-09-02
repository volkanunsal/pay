require 'pay/env'

module Pay
  module Stripe
    include Env
    extend self

    def setup
      ::Stripe.api_key = private_key
      ::StripeEvent.signing_secret = signing_secret
    end

    def public_key
      find_value_by_name(:stripe, :public_key)
    end

    def private_key
      find_value_by_name(:stripe, :private_key)
    end

    def signing_secret
      find_value_by_name(:stripe, :signing_secret)
    end
  end
end
