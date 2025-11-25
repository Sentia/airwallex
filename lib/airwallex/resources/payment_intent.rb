# frozen_string_literal: true

module Airwallex
  class PaymentIntent < APIResource
    extend APIOperations::Create
    extend APIOperations::Retrieve
    extend APIOperations::List
    include APIOperations::Update

    def self.resource_path
      "/api/v1/pa/payment_intents"
    end

    # Confirm the payment intent with payment method details
    def confirm(params = {})
      response = Airwallex.client.post(
        "#{self.class.resource_path}/#{id}/confirm",
        params
      )
      refresh_from(response)
      self
    end

    # Cancel the payment intent
    def cancel(params = {})
      response = Airwallex.client.post(
        "#{self.class.resource_path}/#{id}/cancel",
        params
      )
      refresh_from(response)
      self
    end

    # Capture an authorized payment
    def capture(params = {})
      response = Airwallex.client.post(
        "#{self.class.resource_path}/#{id}/capture",
        params
      )
      refresh_from(response)
      self
    end
  end
end
