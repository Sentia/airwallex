# frozen_string_literal: true

module Airwallex
  # Represents a Connected Account (Scale product) — a sub-account container
  # used to onboard and track funds for a platform's connected entities.
  #
  # @example Create a connected account (business entity)
  #   # account_details is a required top-level wrapper. customer_agreements,
  #   # nickname, and primary_contact are top-level siblings, not nested
  #   # inside it. legal_entity_type is "BUSINESS" or "INDIVIDUAL", not
  #   # "COMPANY" (business_structure below is the field that uses "COMPANY").
  #   # This is a minimal subset of Airwallex's real KYB schema — the full
  #   # schema also supports trustee entities and much more optional detail
  #   # (identity documents, store details, business person details, etc).
  #   account = Airwallex::ConnectedAccount.create(
  #     nickname: "Acme Advertiser",
  #     primary_contact: { email: "contact@acme.example" },
  #     customer_agreements: {
  #       agreed_to_terms_and_conditions: true,
  #       agreed_to_data_usage: true,
  #       terms_and_conditions: { service_agreement_type: "FULL" }
  #     },
  #     account_details: {
  #       legal_entity_type: "BUSINESS",
  #       business_details: {
  #         business_name: "Acme Corp",
  #         business_structure: "COMPANY",
  #         business_address: {
  #           address_line1: "200 Collins Street",
  #           country_code: "AU",
  #           postcode: "3000",
  #           state: "VIC",
  #           suburb: "Melbourne"
  #         }
  #       }
  #     }
  #   )
  #
  # @example Trigger KYC/KYB verification
  #   account.submit
  #
  # @example Look up whichever account you're currently authenticated as
  #   Airwallex::ConnectedAccount.current
  #
  # @example Get the legal_entity_id needed by BillingCustomer/BillingSubscription
  #   account = Airwallex::ConnectedAccount.retrieve("acct_123")
  #   account.legal_entity_id
  class ConnectedAccount < APIResource
    extend APIOperations::Create
    extend APIOperations::Retrieve
    extend APIOperations::List
    include APIOperations::Update

    # Not nested under /accounts/{id} — these endpoints are implicitly
    # scoped to whichever account the request is authenticated as (the
    # platform's own account, or a connected account via x-on-behalf-of).
    CURRENT_ACCOUNT_PATH = "/api/v1/account"
    WALLET_INFO_PATH = "/api/v1/account/wallet_info"

    # @return [String] API resource path for connected accounts
    def self.resource_path
      "/api/v1/accounts"
    end

    # Retrieve whichever account the current request is authenticated as
    #
    # @param params [Hash] additional params
    # @return [ConnectedAccount]
    def self.current(params = {})
      response = Airwallex.client.get(CURRENT_ACCOUNT_PATH, params)
      new(response)
    end

    # Retrieve wallet info for whichever account the current request is
    # authenticated as
    #
    # @param params [Hash] additional params
    # @return [Hash] raw wallet info response
    def self.wallet_info(params = {})
      Airwallex.client.get(WALLET_INFO_PATH, params)
    end

    # The legal_entity_id needed by BillingCustomer.create's
    # default_legal_entity_id and BillingSubscription.create's
    # legal_entity_id — nested inside account_details on this account's own
    # response, not a separate resource.
    #
    # @return [String, nil]
    def legal_entity_id
      attributes.dig(:account_details, :legal_entity_id)
    end

    # Submit the account for KYC/KYB verification
    #
    # @param params [Hash] additional submission params
    # @return [ConnectedAccount] self
    def submit(params = {})
      response = Airwallex.client.post("#{self.class.resource_path}/#{id}/submit", params)
      refresh_from(response)
      self
    end

    # Agree to Airwallex's terms and conditions on behalf of this account
    #
    # @param params [Hash] e.g. agreed_at:, service_agreement_type:,
    #   device_data: { ip_address:, user_agent: }
    # @return [ConnectedAccount] self
    def agree_to_terms_and_conditions(params = {})
      response = Airwallex.client.post(
        "#{self.class.resource_path}/#{id}/terms_and_conditions/agree", params
      )
      refresh_from(response)
      self
    end

    # Suspend this account
    #
    # @param params [Hash] e.g. message: "reason for suspension"
    # @return [ConnectedAccount] self
    def suspend(params = {})
      response = Airwallex.client.post("#{self.class.resource_path}/#{id}/suspend", params)
      refresh_from(response)
      self
    end

    # Reactivate a suspended account
    #
    # @param params [Hash] e.g. message: "reason for reactivation"
    # @return [ConnectedAccount] self
    def reactivate(params = {})
      response = Airwallex.client.post("#{self.class.resource_path}/#{id}/reactivate", params)
      refresh_from(response)
      self
    end
  end
end
