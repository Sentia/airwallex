# frozen_string_literal: true

module Airwallex
  # Represents a Funds Split — how a single PaymentIntent/inbound transaction
  # is divided between the platform and a Connected Account at collection
  # time (the Scale-product mechanism for splitting deposits).
  #
  # @example Create a split
  #   split = Airwallex::FundsSplit.create(
  #     payment_intent_id: intent.id,
  #     splits: [{ account_id: connected_account.id, amount: 50.00 }]
  #   )
  #
  # @example Release the split funds
  #   split.release
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
