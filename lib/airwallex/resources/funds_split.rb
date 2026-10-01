# frozen_string_literal: true

module Airwallex
  # Represents a Funds Split — moves part of a PaymentIntent's funds from the
  # platform account to a Connected Account. Each split has exactly one
  # destination; create one split per connected account.
  #
  # Create errors include duplicate_request (reused request_id) and
  # amount_above_limit (splits exceed the PaymentIntent amount).
  #
  # funds_split.* webhook payloads name the split split_id, not id, and carry
  # no request_id: { split_id:, status:, amount:, currency:, source_id:,
  # source_type:, destination:, ... }.
  #
  # @example Create a split
  #   split = Airwallex::FundsSplit.create(
  #     request_id: "split-req-123",   # required, max 64
  #     source_id: intent.id,          # required, PaymentIntent id
  #     source_type: "PAYMENT_INTENT", # required
  #     amount: "50.00",               # required, string
  #     destination: connected_account.id,
  #     auto_release: true,            # optional, default true
  #     metadata: { order_id: "123" }  # optional
  #   )
  #
  # @example Release the split funds (when created with auto_release: false)
  #   split.release
  #
  # @see FundsSplitReversal to move split funds back to the platform
  class FundsSplit < APIResource
    extend APIOperations::Create
    extend APIOperations::Retrieve
    extend APIOperations::List

    # @return [String] API resource path for funds splits
    def self.resource_path
      "/api/v1/pa/funds_splits"
    end

    # Release this funds split (make the split amount available to the
    # connected account)
    #
    # @param params [Hash] additional params
    # @return [FundsSplit] self
    def release(params = {})
      response = Airwallex.client.post("#{self.class.resource_path}/#{id}/release", params)
      refresh_from(response)
      self
    end
  end
end
