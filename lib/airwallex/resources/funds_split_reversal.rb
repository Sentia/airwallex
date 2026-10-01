# frozen_string_literal: true

module Airwallex
  # Represents a Funds Split Reversal — moves previously split funds back from
  # the connected account (the split's destination) to the platform account.
  # Partial reversals are allowed until the full split amount is reversed.
  #
  # Statuses: CREATED, RELEASED, SETTLED.
  #
  # @example Reverse part of a split
  #   reversal = Airwallex::FundsSplitReversal.create(
  #     request_id: "rev-req-123",  # required, max 64
  #     funds_split_id: split.id,   # required
  #     amount: "5.00",             # required, string
  #     metadata: { reason: "refund" }
  #   )
  #   reversal.status # => "CREATED"
  #
  # @example List the reversals of a split
  #   Airwallex::FundsSplitReversal.list(funds_split_id: split.id)
  class FundsSplitReversal < APIResource
    extend APIOperations::Create
    extend APIOperations::Retrieve
    extend APIOperations::List

    # @return [String] API resource path for funds split reversals
    def self.resource_path
      "/api/v1/pa/funds_split_reversals"
    end
  end
end
