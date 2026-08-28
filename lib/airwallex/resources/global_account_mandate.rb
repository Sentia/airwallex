# frozen_string_literal: true

module Airwallex
  # Represents a direct debit mandate on a GlobalAccount. Always accessed
  # through its parent GlobalAccount, since its API path is scoped by
  # global_account_id.
  class GlobalAccountMandate < APIResource
    # @param global_account_id [String] the parent GlobalAccount's id
    # @return [String] API resource path for this account's mandates
    def self.resource_path(global_account_id)
      "/api/v1/global_accounts/#{global_account_id}/mandates"
    end

    # Cancel this mandate
    #
    # @param params [Hash] additional params
    # @return [GlobalAccountMandate] self
    def cancel(params = {})
      response = Airwallex.client.post(
        "#{self.class.resource_path(global_account_id)}/#{id}/cancel", params
      )
      refresh_from(response)
      self
    end
  end
end
