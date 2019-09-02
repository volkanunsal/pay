# frozen_string_literal: true

# rubocop:disable Lint/HandleExceptions
begin
  require 'stripe'
  require 'stripe_event'
rescue LoadError
end
# rubocop:enable Lint/HandleExceptions

module Pay
  class Engine < ::Rails::Engine
    engine_name 'pay'

    initializer 'pay.processors' do |app|
      require 'pay/stripe'
    end

    config.to_prepare do
      Pay::Stripe.setup
    end
  end
end
