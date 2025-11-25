# frozen_string_literal: true

module Airwallex
  # Represents a refund of a payment intent
  #
  # Refunds can be full or partial. Multiple refunds can be created for a single
  # payment intent as long as the total refunded amount doesn't exceed the original amount.
  #
  # @example Create a full refund
  #   refund = Airwallex::Refund.create(
  #     payment_intent_id: "pi_123",
  #     amount: 100.00,
  #     reason: "requested_by_customer"
  #   )
  #
  # @example Create a partial refund
  #   refund = Airwallex::Refund.create(
  #     payment_intent_id: "pi_123",
  #     amount: 25.00
  #   )
  #
  # @example List refunds for a payment
  #   refunds = Airwallex::Refund.list(payment_intent_id: "pi_123")
  class Refund < APIResource
    extend APIOperations::Create
    extend APIOperations::Retrieve
    extend APIOperations::List

    # @return [String] API resource path for refunds
    def self.resource_path
      "/api/v1/pa/refunds"
    end
  end
end
