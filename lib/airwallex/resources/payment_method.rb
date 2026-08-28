# frozen_string_literal: true

module Airwallex
  # Represents a payment method (card, bank account, etc.) that can be reused
  #
  # Payment methods allow you to store customer payment credentials securely
  # and reuse them for future payments without collecting details again.
  #
  # Note: raw card tokenization via .create requires PCI-scoped "Native API"
  # account access, which isn't enabled by default — if your account isn't
  # provisioned for it, collect cards via Airwallex's hosted checkout or
  # Embedded Elements instead.
  #
  # @example Create a card payment method
  #   pm = Airwallex::PaymentMethod.create(
  #     type: "card",
  #     card: {
  #       number: "4242424242424242",
  #       expiry_month: "12",
  #       expiry_year: "2025",
  #       cvc: "123"
  #     },
  #     billing: {
  #       first_name: "John",
  #       email: "john@example.com"
  #     }
  #   )
  #
  # @example Use saved payment method
  #   payment_intent.confirm(payment_method_id: pm.id)
  #
  # @example Update billing details
  #   pm.update(billing: { address: { postal_code: "10001" } })
  #
  # @example Disable a payment method
  #   pm.disable
  class PaymentMethod < APIResource
    extend APIOperations::Create
    extend APIOperations::Retrieve
    extend APIOperations::List
    include APIOperations::Update

    # @return [String] API resource path for payment methods
    def self.resource_path
      "/api/v1/pa/payment_methods"
    end

    # Disable this payment method (Airwallex has no delete/detach endpoint;
    # disabling is the real lifecycle operation and preserves history)
    #
    # @param params [Hash] additional params
    # @return [PaymentMethod] self
    def disable(params = {})
      response = Airwallex.client.post("#{self.class.resource_path}/#{id}/disable", params)
      refresh_from(response)
      self
    end
  end
end
