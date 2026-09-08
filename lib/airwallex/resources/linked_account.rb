# frozen_string_literal: true

module Airwallex
  # Represents a Linked Account — a customer's external bank account
  # authorized for Direct Debit pulls.
  #
  # This gem currently only implements the sandbox Simulation endpoints for
  # the mandate and micro-deposit lifecycle; it does not yet implement the
  # live create/retrieve/list endpoints. All four actions below return
  # HTTP 200 with an empty body on success, so they return `true` rather
  # than a resource instance.
  # See https://www.airwallex.com/docs/api/simulation/linked-accounts
  #
  # MANDATE STATUS LIFECYCLE:
  #   PROCESSING -> ACTIVE   (simulate_accept_mandate)
  #   PROCESSING -> INACTIVE (simulate_reject_mandate)
  #   PROCESSING or ACTIVE -> INACTIVE (simulate_cancel_mandate)
  #
  # @example Approve a mandate that's awaiting the customer's bank
  #   Airwallex::LinkedAccount.simulate_accept_mandate("la_123")
  class LinkedAccount < APIResource
    # @return [String] API resource path for simulated linked account actions
    def self.resource_path
      "/api/v1/simulation/linked_accounts"
    end

    # Simulate the mandate transitioning PROCESSING -> ACTIVE
    #
    # @param linked_account_id [String]
    # @return [true]
    def self.simulate_accept_mandate(linked_account_id)
      Airwallex.client.post("#{resource_path}/#{linked_account_id}/mandate/accept", {})
      true
    end

    # Simulate the mandate transitioning PROCESSING -> INACTIVE
    #
    # @param linked_account_id [String]
    # @return [true]
    def self.simulate_reject_mandate(linked_account_id)
      Airwallex.client.post("#{resource_path}/#{linked_account_id}/mandate/reject", {})
      true
    end

    # Simulate the mandate transitioning PROCESSING or ACTIVE -> INACTIVE
    #
    # @param linked_account_id [String]
    # @return [true]
    def self.simulate_cancel_mandate(linked_account_id)
      Airwallex.client.post("#{resource_path}/#{linked_account_id}/mandate/cancel", {})
      true
    end

    # Simulate a failed micro-deposit verification, transitioning the
    # linked account itself from REQUIRES_ACTION to FAILED
    #
    # @param linked_account_id [String]
    # @return [true]
    def self.simulate_fail_microdeposits(linked_account_id)
      Airwallex.client.post("#{resource_path}/#{linked_account_id}/fail_microdeposits", {})
      true
    end
  end
end
