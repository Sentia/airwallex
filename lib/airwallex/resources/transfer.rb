# frozen_string_literal: true

module Airwallex
  class Transfer < APIResource
    extend APIOperations::Create
    extend APIOperations::Retrieve
    extend APIOperations::List

    # Sandbox-only — see https://www.airwallex.com/docs/api/simulation/transfers
    SIMULATION_PATH = "/api/v1/simulation/transfers"

    def self.resource_path
      "/api/v1/transfers"
    end

    # Cancel a pending transfer
    #
    # @param opts [Hash] headers: (e.g. { "x-on-behalf-of" => account_id })
    # @return [Transfer] self
    def cancel(opts = {})
      response = Airwallex.client.post(
        "#{self.class.resource_path}/#{id}/cancel",
        {},
        opts[:headers] || {}
      )
      refresh_from(response)
      self
    end

    # Simulate this transfer's status advancing one step. The standard
    # lifecycle is SCHEDULED -> PROCESSING -> SENT -> PAID, progressed one
    # step at a time (the sandbox rejects PROCESSING -> PAID with a 500
    # operation_failed; go through SENT); OVERDUE, FAILED, and CANCELLED can
    # be jumped to directly.
    #
    # @param next_status [String] one of "OVERDUE", "PROCESSING", "SENT",
    #   "PAID", "FAILED", "CANCELLED"
    # @param failure_type [String, nil] failure reason code, only
    #   meaningful when next_status is "FAILED"
    # @param headers [Hash] e.g. { "x-on-behalf-of" => account_id } — required
    #   for a transfer created on behalf of a connected account
    # @return [Transfer] self
    def simulate_transition(next_status:, failure_type: nil, headers: {})
      params = { next_status: next_status }
      params[:failure_type] = failure_type if failure_type
      response = Airwallex.client.post("#{SIMULATION_PATH}/#{id}/transition", params, headers)
      refresh_from(response)
      self
    end

    # Simulate a transfer's status advancing one step
    #
    # @param transfer_id [String]
    # @param next_status [String] one of "OVERDUE", "PROCESSING", "SENT",
    #   "PAID", "FAILED", "CANCELLED"
    # @param failure_type [String, nil] failure reason code, only
    #   meaningful when next_status is "FAILED"
    # @param headers [Hash] e.g. { "x-on-behalf-of" => account_id } — required
    #   for a transfer created on behalf of a connected account
    # @return [Transfer]
    def self.simulate_transition(transfer_id, next_status:, failure_type: nil, headers: {})
      params = { next_status: next_status }
      params[:failure_type] = failure_type if failure_type
      response = Airwallex.client.post("#{SIMULATION_PATH}/#{transfer_id}/transition", params, headers)
      new(response)
    end
  end
end
