# frozen_string_literal: true

module Airwallex
  # BatchTransfer resource for bulk payout operations
  #
  # Batch transfers allow creating multiple transfers in a single API call,
  # improving efficiency for bulk payout scenarios like marketplace payouts or payroll.
  #
  # @example Create a batch transfer
  #   batch = Airwallex::BatchTransfer.create(
  #     request_id: "batch_#{Time.now.to_i}",
  #     source_currency: "USD",
  #     transfers: [
  #       { beneficiary_id: "ben_001", amount: 100.00, reason: "Payout 1" },
  #       { beneficiary_id: "ben_002", amount: 200.00, reason: "Payout 2" }
  #     ]
  #   )
  #
  # @example Retrieve a batch transfer
  #   batch = Airwallex::BatchTransfer.retrieve("batch_123")
  #   batch.transfers.each { |t| puts "#{t.id}: #{t.status}" }
  #
  class BatchTransfer < APIResource
    extend APIOperations::Create
    extend APIOperations::Retrieve
    extend APIOperations::List

    def self.resource_path
      "/api/v1/batch_transfers"
    end
  end
end
