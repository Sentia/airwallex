# frozen_string_literal: true

module Airwallex
  # Represents an alias (e.g. PayID, email, or phone-linked VAN) attached to
  # a GlobalAccount. Always accessed through its parent GlobalAccount, since
  # its API path is scoped by global_account_id.
  class GlobalAccountAlias < APIResource
    # @param global_account_id [String] the parent GlobalAccount's id
    # @return [String] API resource path for this account's aliases
    def self.resource_path(global_account_id)
      "/api/v1/global_accounts/#{global_account_id}/aliases"
    end

    # Begin porting this alias in from another provider
    #
    # @param params [Hash] additional porting params
    # @return [GlobalAccountAlias] self
    def initiate_port(params = {})
      response = Airwallex.client.post(
        "#{self.class.resource_path(global_account_id)}/#{id}/initiate_port", params
      )
      refresh_from(response)
      self
    end

    # Submit the verification code sent to confirm this alias
    #
    # @param params [Hash] e.g. code:
    # @return [GlobalAccountAlias] self
    def submit_verification_code(params = {})
      response = Airwallex.client.post(
        "#{self.class.resource_path(global_account_id)}/#{id}/submit_verification_code", params
      )
      refresh_from(response)
      self
    end

    # Request a new verification code for this alias
    #
    # @param params [Hash] additional params
    # @return [GlobalAccountAlias] self
    def request_new_verification_code(params = {})
      response = Airwallex.client.post(
        "#{self.class.resource_path(global_account_id)}/#{id}/request_new_verification_code", params
      )
      refresh_from(response)
      self
    end

    # Cancel this alias
    #
    # @param params [Hash] additional params
    # @return [GlobalAccountAlias] self
    def cancel(params = {})
      response = Airwallex.client.post(
        "#{self.class.resource_path(global_account_id)}/#{id}/cancel", params
      )
      refresh_from(response)
      self
    end
  end
end
