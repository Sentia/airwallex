# frozen_string_literal: true

module Airwallex
  # Represents a Connected Account Transfer — moves funds between the platform
  # account and a connected account's wallet. Send x-on-behalf-of to debit a
  # connected account instead of the platform.
  #
  # Statuses: NEW, PENDING, SETTLED, SUSPENDED, FAILED. Create errors include
  # insufficient_fund and request_id_duplicate.
  #
  # @example Fund a connected account from the platform
  #   transfer = Airwallex::ConnectedAccountTransfer.create(
  #     request_id: "cat-req-123",  # required, 1-50
  #     amount: "100.00",
  #     currency: "AUD",
  #     destination: "acct_123",    # connected account id
  #     reason: "transfer_to_own_account",
  #     reference: "Ledger top-up"  # required, 1-140
  #   )
  #
  # @example List settled transfers to an account
  #   Airwallex::ConnectedAccountTransfer.list(destination: "acct_123", status: "SETTLED")
  class ConnectedAccountTransfer < APIResource
    extend APIOperations::Create
    extend APIOperations::Retrieve
    extend APIOperations::List

    # @return [String] API resource path for connected account transfers
    def self.resource_path
      "/api/v1/connected_account_transfers"
    end
  end
end
