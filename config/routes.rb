# frozen_string_literal: true

Pay::Engine.routes.draw do
  post 'stripe', to: 'stripe_event/webhook#event'
end
