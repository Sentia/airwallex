# frozen_string_literal: true

module Airwallex
  class PaymentIntent < APIResource
    extend APIOperations::Create
    extend APIOperations::Retrieve
    extend APIOperations::List
    include APIOperations::Update

    # Sandbox-only — see https://www.airwallex.com/docs/api/simulation/shopper-actions
    SIMULATION_SHOPPER_ACTION_PATH = "/api/v1/simulation/pa/shopper_actions"

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

    # Simulate the shopper completing a redirect/3DS challenge raised during
    # #confirm, using the `url` from the confirm response's next_action
    #
    # @param url [String] the redirect URL from #confirm's next_action
    # @return [PaymentIntent] self
    def simulate_shopper_pay(url:)
      response = Airwallex.client.post("#{SIMULATION_SHOPPER_ACTION_PATH}/pay", url: url)
      refresh_from(response)
      self
    end

    # Simulate the shopper abandoning/rejecting a redirect/3DS challenge
    # raised during #confirm, using the `url` from the confirm response's
    # next_action
    #
    # @param url [String] the redirect URL from #confirm's next_action
    # @return [PaymentIntent] self
    def simulate_shopper_reject(url:)
      response = Airwallex.client.post("#{SIMULATION_SHOPPER_ACTION_PATH}/reject", url: url)
      refresh_from(response)
      self
    end
  end
end
