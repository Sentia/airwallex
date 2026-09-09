# frozen_string_literal: true

module Airwallex
  # Represents a Request for Information (RFI) — a compliance question
  # Airwallex raises against your account (KYC, an ongoing KYC review, a
  # cardholder, a transaction, payment enablement, or merchant risk).
  #
  # This gem currently only implements the sandbox Simulation endpoints
  # (there is no live create — real RFIs originate from Airwallex's own
  # compliance review, same as Dispute). See
  # https://www.airwallex.com/docs/api/simulation/request-for-information
  #
  # @example Raise a KYC RFI, then close it
  #   rfi = Airwallex::RFI.simulate_create(
  #     type: "KYC",
  #     questions: [{ answer: { type: "TEXT" } }]
  #   )
  #   rfi.simulate_close
  class RFI < APIResource
    # @return [String] API resource path for simulated RFI actions
    def self.resource_path
      "/api/v1/simulation/rfis"
    end

    # Simulate Airwallex raising an RFI
    #
    # @param params [Hash] type: (required, one of "KYC", "KYC_ONGOING",
    #   "CARDHOLDER", "TRANSACTION", "PAYMENT_ENABLEMENT",
    #   "MERCHANT_RISK"); questions: (required, array of
    #   { answer: { type: }, sources: [] })
    # @return [RFI]
    def self.simulate_create(params = {})
      response = Airwallex.client.post("#{resource_path}/create", params)
      new(response)
    end

    # Simulate closing an RFI
    #
    # @param rfi_id [String]
    # @return [RFI]
    def self.simulate_close(rfi_id)
      response = Airwallex.client.post("#{resource_path}/#{rfi_id}/close", {})
      new(response)
    end

    # Simulate a follow-up on an RFI — reopen an existing answered question
    # (by id) or append a new one
    #
    # @param rfi_id [String]
    # @param params [Hash] questions: (required, array of
    #   { id: } or { answer: { type: }, sources: [] })
    # @return [RFI]
    def self.simulate_follow_up(rfi_id, params = {})
      response = Airwallex.client.post("#{resource_path}/#{rfi_id}/follow_up", params)
      new(response)
    end

    # Simulate closing this RFI
    #
    # @return [RFI] self
    def simulate_close
      response = Airwallex.client.post("#{self.class.resource_path}/#{id}/close", {})
      refresh_from(response)
      self
    end

    # Simulate a follow-up on this RFI
    #
    # @param params [Hash] questions: (required)
    # @return [RFI] self
    def simulate_follow_up(params = {})
      response = Airwallex.client.post("#{self.class.resource_path}/#{id}/follow_up", params)
      refresh_from(response)
      self
    end
  end
end
