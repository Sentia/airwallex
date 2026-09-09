# frozen_string_literal: true

module Airwallex
  # Represents an offboarding request for a Connected Account. Always
  # accessed through its parent ConnectedAccount, since its API path is
  # scoped by account_id.
  #
  # This gem currently only implements the sandbox Simulation endpoints for
  # completing/cancelling an offboarding; it does not yet implement the live
  # create/retrieve/list endpoints (`/api/v1/accounts/{account_id}/offboardings`).
  # See https://www.airwallex.com/docs/api/simulation/connected-account-offboarding
  #
  # @example Simulate an offboarding finishing
  #   Airwallex::AccountOffboarding.simulate_complete("acct_123", "obd_456")
  class AccountOffboarding < APIResource
    # @param account_id [String] the parent ConnectedAccount's id
    # @return [String] API resource path for this account's simulated
    #   offboarding actions
    def self.resource_path(account_id)
      "/api/v1/simulation/accounts/#{account_id}/offboardings"
    end

    # Simulate an offboarding completing
    #
    # @param account_id [String]
    # @param offboarding_id [String]
    # @return [AccountOffboarding]
    def self.simulate_complete(account_id, offboarding_id)
      response = Airwallex.client.post("#{resource_path(account_id)}/#{offboarding_id}/complete", {})
      new(response)
    end

    # Simulate an offboarding being cancelled
    #
    # @param account_id [String]
    # @param offboarding_id [String]
    # @return [AccountOffboarding]
    def self.simulate_cancel(account_id, offboarding_id)
      response = Airwallex.client.post("#{resource_path(account_id)}/#{offboarding_id}/cancel", {})
      new(response)
    end
  end
end
