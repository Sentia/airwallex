# frozen_string_literal: true

module Airwallex
  # Represents a payment method (card, bank account, etc.) that can be reused
  #
  # Payment methods allow you to store customer payment credentials securely
  # and reuse them for future payments without collecting details again.
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
  class PaymentMethod < APIResource
    extend APIOperations::Create
    extend APIOperations::Retrieve
    extend APIOperations::List
    extend APIOperations::Update
    include APIOperations::Update
    extend APIOperations::Delete

    # @return [String] API resource path for payment methods
    def self.resource_path
      "/api/v1/pa/payment_methods"
    end

    # Detach this payment method from its customer
    #
    # @return [PaymentMethod] self
    def detach
      response = Airwallex.client.post("#{self.class.resource_path}/#{id}/detach", {})
      refresh_from(response)
      self
    end
  end
end
