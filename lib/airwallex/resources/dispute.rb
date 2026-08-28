# frozen_string_literal: true

module Airwallex
  # Dispute resource for handling chargebacks and payment disputes
  #
  # Disputes represent chargebacks or payment disputes initiated by cardholders.
  # Merchants can view disputes, challenge them with evidence, or accept them.
  # There is no create — disputes originate from card networks/issuing banks.
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
  class Dispute < APIResource
    extend APIOperations::Retrieve
    extend APIOperations::List
    include APIOperations::Update

    def self.resource_path
      "/api/v1/pa/payment_disputes"
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
