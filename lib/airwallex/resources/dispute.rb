# frozen_string_literal: true

module Airwallex
  # Dispute resource for handling chargebacks and payment disputes
  #
  # Disputes represent chargebacks or payment disputes initiated by cardholders.
  # Merchants can view disputes, challenge them with evidence, or accept them.
  # There is no live create — real disputes originate from card
  # networks/issuing banks. In the sandbox, `.simulate_create` (and
  # `#simulate_escalate`/`#simulate_resolve`) stand in for the card
  # network/issuing bank to drive the full dispute lifecycle for testing.
  # See https://www.airwallex.com/docs/api/simulation/payment-disputes
  #
  # @example List open disputes
  #   disputes = Airwallex::Dispute.list(status: 'OPEN')
  #
  # @example Retrieve a dispute
  #   dispute = Airwallex::Dispute.retrieve('dis_123')
  #
  # @example Accept a dispute
  #   dispute.accept
  #
  # @example Challenge a dispute
  #   dispute.challenge(...)
  #
  # @example Simulate the full sandbox lifecycle
  #   dispute = Airwallex::Dispute.simulate_create(
  #     payment_intent_id: "int_123",
  #     reason_code: "4853",
  #     stage: "CHARGEBACK",
  #     due_at: "2026-12-01T23:59:59Z"
  #   )
  #   dispute.challenge(customer_communication: "Email thread")
  #   dispute.simulate_resolve(in_favor_of: "MERCHANT")
  class Dispute < APIResource
    extend APIOperations::Retrieve
    extend APIOperations::List
    include APIOperations::Update

    # Sandbox-only — see https://www.airwallex.com/docs/api/simulation/payment-disputes
    SIMULATION_PATH = "/api/v1/simulation/pa/payment_disputes"

    def self.resource_path
      "/api/v1/pa/payment_disputes"
    end

    # Simulate a card network/issuing bank raising a dispute against a
    # PaymentIntent
    #
    # @param params [Hash] payment_intent_id:, reason_code: (card-brand
    #   specific, e.g. Mastercard "4853", Visa "10.4"), stage: (one of
    #   "RFI", "PRE_CHARGEBACK", "CHARGEBACK", "PRE_ARBITRATION",
    #   "ARBITRATION"), due_at: (required); amount:, comment:, documents:
    #   (optional)
    # @return [Dispute]
    def self.simulate_create(params = {})
      response = Airwallex.client.post("#{SIMULATION_PATH}/create", params)
      new(response)
    end

    # Simulate the issuing bank rejecting the merchant's challenge evidence
    # and advancing the dispute to the next stage (e.g. Chargeback ->
    # Pre-arbitration). Not valid while status is REQUIRES_RESPONSE — the
    # merchant must #accept or #challenge first.
    #
    # @param dispute_id [String]
    # @param params [Hash] due_at: (required); amount:, comment:,
    #   documents: (optional)
    # @return [Dispute]
    def self.simulate_escalate(dispute_id, params = {})
      response = Airwallex.client.post("#{SIMULATION_PATH}/#{dispute_id}/escalate", params)
      new(response)
    end

    # Simulate the issuing bank's final decision on a dispute.
    # in_favor_of: "MERCHANT" resolves it WON/REVERSED; "CUSTOMER" resolves
    # it LOST. Not valid while status is REQUIRES_RESPONSE — the merchant
    # must #accept or #challenge first.
    #
    # @param dispute_id [String]
    # @param params [Hash] in_favor_of: ("MERCHANT" or "CUSTOMER",
    #   required); amount: (optional, defaults to the full disputed amount)
    # @return [Dispute]
    def self.simulate_resolve(dispute_id, params = {})
      response = Airwallex.client.post("#{SIMULATION_PATH}/#{dispute_id}/resolve", params)
      new(response)
    end

    # Accept a dispute without challenging it
    #
    # @return [Airwallex::Dispute] self
    def accept
      response = Airwallex.client.post("#{self.class.resource_path}/#{id}/accept", {})
      refresh_from(response)
      self
    end

    # Challenge a dispute with evidence
    #
    # @param params [Hash] challenge params — exact shape unconfirmed, pass
    #   through whatever Airwallex's challenge schema requires
    # @return [Airwallex::Dispute] self
    def challenge(params = {})
      response = Airwallex.client.post("#{self.class.resource_path}/#{id}/challenge", params)
      refresh_from(response)
      self
    end

    # Simulate the issuing bank rejecting this dispute's challenge evidence
    # and advancing it to the next stage
    #
    # @param params [Hash] due_at: (required); amount:, comment:,
    #   documents: (optional)
    # @return [Airwallex::Dispute] self
    def simulate_escalate(params = {})
      response = Airwallex.client.post("#{self.class::SIMULATION_PATH}/#{id}/escalate", params)
      refresh_from(response)
      self
    end

    # Simulate the issuing bank's final decision on this dispute
    #
    # @param params [Hash] in_favor_of: ("MERCHANT" or "CUSTOMER",
    #   required); amount: (optional)
    # @return [Airwallex::Dispute] self
    def simulate_resolve(params = {})
      response = Airwallex.client.post("#{self.class::SIMULATION_PATH}/#{id}/resolve", params)
      refresh_from(response)
      self
    end

    # List payment intents related to this dispute
    #
    # @param params [Hash] additional query params (e.g. pagination)
    # @return [ListObject<PaymentIntent>]
    def related_payment_intents(params = {})
      response = Airwallex.client.get(
        "#{self.class.resource_path}/#{id}/related_payment_intents", params
      )

      ListObject.new(
        data: extract_items(response),
        has_more: extract_has_more(response),
        next_cursor: extract_next_cursor(response),
        resource_class: PaymentIntent,
        params: params
      )
    end

    private

    def extract_items(response)
      return response if response.is_a?(Array)

      response[:items] || response["items"] || response[:data] || response["data"] || []
    end

    def extract_has_more(response)
      return false unless response.is_a?(Hash)

      response[:has_more] || response["has_more"] || false
    end

    def extract_next_cursor(response)
      return nil unless response.is_a?(Hash)

      response[:next_cursor] || response["next_cursor"]
    end
  end
end
