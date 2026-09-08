# frozen_string_literal: true

module Airwallex
  # Represents a Deposit — funds arriving in your Airwallex account, either
  # as an inbound bank transfer into a Global Account (type: BANK_TRANSFER)
  # or a Direct Debit pull from a verified LinkedAccount (type:
  # DIRECT_DEBIT, made via .create).
  #
  # The sandbox Simulation actions split cleanly along that same line:
  # .simulate_create simulates a BANK_TRANSFER deposit landing, and it
  # auto-settles on its own within a few seconds — same as a real bank
  # transfer, there's no PENDING state to force through. .simulate_settle/
  # .simulate_reject/.simulate_reverse only operate on DIRECT_DEBIT
  # deposits made via .create, since a real direct debit pull takes days
  # to clear and the sandbox has no other way to resolve it. Calling
  # settle/reject/reverse on a BANK_TRANSFER deposit's id returns a 404
  # "Deposit does not exist" — confirmed against the real sandbox.
  # See https://www.airwallex.com/docs/api/simulation/deposits
  #
  # @example Simulate an inbound bank transfer landing (settles on its own)
  #   Airwallex::Deposit.simulate_create(amount: 100.00, global_account_id: "gacc_123")
  #
  # @example Pull via Direct Debit, then force it through the sandbox lifecycle
  #   deposit = Airwallex::Deposit.create(
  #     funding_source_id: "la_123", # a verified LinkedAccount id
  #     amount: 50.00,
  #     currency: "AUD"
  #   )
  #   deposit.simulate_settle
  class Deposit < APIResource
    extend APIOperations::Create
    extend APIOperations::Retrieve
    extend APIOperations::List

    # Airwallex's own API is inconsistent here: simulating a bank-transfer
    # deposit landing uses the singular "deposit", while every other
    # simulation action on an existing deposit uses the plural "deposits".
    SIMULATE_CREATE_PATH = "/api/v1/simulation/deposit/create"
    SIMULATION_PATH = "/api/v1/simulation/deposits"

    # @return [String] API resource path for deposits
    def self.resource_path
      "/api/v1/deposits"
    end

    # Simulate an inbound bank-transfer deposit landing in a Global
    # Account
    #
    # @param params [Hash] amount:, global_account_id: (required);
    #   payer_bankname:, payer_country:, payer_name:, reference:,
    #   statement_ref:, status: ("PENDING", "REJECTED", or "SETTLED",
    #   defaults to "SETTLED") (optional)
    # @return [Deposit]
    def self.simulate_create(params = {})
      response = Airwallex.client.post(SIMULATE_CREATE_PATH, params)
      new(response)
    end

    # Simulate a PENDING Direct Debit deposit (made via .create) settling
    #
    # @param deposit_id [String]
    # @return [Deposit]
    def self.simulate_settle(deposit_id)
      response = Airwallex.client.post("#{SIMULATION_PATH}/#{deposit_id}/settle", {})
      new(response)
    end

    # Simulate a PENDING Direct Debit deposit (made via .create) being
    # rejected
    #
    # @param deposit_id [String]
    # @return [Deposit]
    def self.simulate_reject(deposit_id)
      response = Airwallex.client.post("#{SIMULATION_PATH}/#{deposit_id}/reject", {})
      new(response)
    end

    # Simulate reversing a SETTLED Direct Debit deposit (creates an
    # offsetting settled deposit and deactivates the LinkedAccount)
    #
    # @param deposit_id [String]
    # @return [Deposit]
    def self.simulate_reverse(deposit_id)
      response = Airwallex.client.post("#{SIMULATION_PATH}/#{deposit_id}/reverse", {})
      new(response)
    end

    # Simulate this Direct Debit deposit settling
    #
    # @return [Deposit] self
    def simulate_settle
      response = Airwallex.client.post("#{self.class::SIMULATION_PATH}/#{id}/settle", {})
      refresh_from(response)
      self
    end

    # Simulate this Direct Debit deposit being rejected
    #
    # @return [Deposit] self
    def simulate_reject
      response = Airwallex.client.post("#{self.class::SIMULATION_PATH}/#{id}/reject", {})
      refresh_from(response)
      self
    end

    # Simulate reversing this Direct Debit deposit
    #
    # @return [Deposit] self
    def simulate_reverse
      response = Airwallex.client.post("#{self.class::SIMULATION_PATH}/#{id}/reverse", {})
      refresh_from(response)
      self
    end
  end
end
