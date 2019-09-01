# frozen_string_literal: true

require 'test_helper'

class WebhookRoutesTest < ActionDispatch::IntegrationTest
  test 'stripe webhook routes get mounted correctly' do
    ::StripeEvent::WebhookController
      .any_instance.stubs(:verified_event).returns(OpenStruct.new)

    post '/webhooks/stripe', as: :json
    assert_equal 200, response.status
  end
end
