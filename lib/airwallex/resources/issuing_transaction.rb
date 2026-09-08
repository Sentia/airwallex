# frozen_string_literal: true

module Airwallex
  # Represents a card (Issuing) transaction event.
  #
  # This gem currently only implements the sandbox Simulation endpoints for
  # issuing transactions — creating an authorization, capturing/reversing a
  # PENDING one, refunding a CAPTURED one, and delivering a 3DS delegation
  # notification. It does not yet implement the live Issuing resources
  # (Card, Cardholder) or the live transaction retrieve/list endpoints.
  # See https://www.airwallex.com/docs/api/simulation/issuing-transactions
  #
  # @example Authorize, then capture in full
  #   txn = Airwallex::IssuingTransaction.simulate_create(
  #     card_id: "card_123",
  #     transaction_amount: 25.00,
  #     transaction_currency: "USD"
  #   )
  #   Airwallex::IssuingTransaction.simulate_capture(txn.transaction_id)
  #
  # @example Authorize and clear in a single step
  #   Airwallex::IssuingTransaction.simulate_create(
  #     card_id: "card_123",
  #     transaction_amount: 25.00,
  #     transaction_currency: "USD",
  #     single_phase: true
  #   )
  class IssuingTransaction < APIResource
    # @return [String] API resource path for simulated issuing transactions
    def self.resource_path
      "/api/v1/simulation/issuing"
    end

    # Simulate a card authorization (or, with single_phase: true, an
    # authorization cleared in one step)
    #
    # @param params [Hash] card_id: (or card_number:), transaction_amount:,
    #   transaction_currency: (required); single_phase:, auth_code:,
    #   merchant_category_code:, merchant_info:, transaction_failure_reason:
    #   (optional)
    # @return [IssuingTransaction] the resulting transaction — read its
    #   `transaction_id` to pass to .simulate_capture/.simulate_reverse
    def self.simulate_create(params = {})
      response = Airwallex.client.post("#{resource_path}/create", params)
      new(response)
    end

    # Simulate capturing a PENDING transaction
    #
    # @param transaction_id [String] the `transaction_id` from
    #   .simulate_create's response
    # @param params [Hash] merchant_info:, transaction_amount: (optional —
    #   a partial capture if less than the authorized amount, full amount
    #   if omitted)
    # @return [IssuingTransaction]
    def self.simulate_capture(transaction_id, params = {})
      response = Airwallex.client.post(
        "#{resource_path}/card_transaction_lifecycles/#{transaction_id}/capture", params
      )
      new(response)
    end

    # Simulate reversing a PENDING transaction
    #
    # @param transaction_id [String] the `transaction_id` from
    #   .simulate_create's response
    # @param params [Hash] transaction_amount: (optional — a partial
    #   reversal if less than the authorized amount, full reversal if
    #   omitted)
    # @return [IssuingTransaction]
    def self.simulate_reverse(transaction_id, params = {})
      response = Airwallex.client.post(
        "#{resource_path}/card_transaction_lifecycles/#{transaction_id}/reverse", params
      )
      new(response)
    end

    # Simulate refunding a CAPTURED, not-fully-refunded transaction back to
    # the card
    #
    # @param params [Hash] card_id: (or card_number:), transaction_amount:,
    #   transaction_currency: (required); merchant_category_code:,
    #   merchant_info: (optional)
    # @return [IssuingTransaction]
    def self.simulate_refund(params = {})
      response = Airwallex.client.post("#{resource_path}/refund", params)
      new(response)
    end

    # Simulate a 3DS delegation-mode notification for a card
    #
    # @param params [Hash] card_number: (required); merchant_info: (object,
    #   optional: acquirer_id:, merchant_category_code:,
    #   merchant_country_code:, merchant_id:, merchant_name:, merchant_url:)
    # @return [Hash] raw response
    def self.simulate_notify_three_ds(params = {})
      Airwallex.client.post("#{resource_path}/threeds/notify", params)
    end
  end
end
