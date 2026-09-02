# frozen_string_literal: true

module Airwallex
  # Represents a Global Account (Virtual Account Number) used to collect
  # local bank transfers into a specific currency and jurisdiction.
  #
  # @example Provision a VAN
  #   account = Airwallex::GlobalAccount.create(
  #     country_code: "AU",
  #     nick_name: "booking_12345",
  #     required_features: [{ transfer_method: "LOCAL" }]
  #   )
  #
  # @example Reconcile inbound deposits
  #   account.transactions.each { |txn| puts "#{txn.amount} from #{txn.remitter}" }
  #
  # @example Add and verify an alias (e.g. a phone number or email VAN)
  #   alias_record = account.create_alias(type: "PAYID_PHONE", value: "+61400000000")
  #   alias_record.submit_verification_code(code: "123456")
  class GlobalAccount < APIResource
    extend APIOperations::Create
    extend APIOperations::Retrieve
    extend APIOperations::List
    include APIOperations::Update

    # @return [String] API resource path for global accounts
    def self.resource_path
      "/api/v1/global_accounts"
    end

    # Close this global account
    #
    # @param params [Hash] additional closure params
    # @return [GlobalAccount] self
    def close(params = {})
      response = Airwallex.client.post("#{self.class.resource_path}/#{id}/close", params)
      refresh_from(response)
      self
    end

    # Generate a bank-ownership statement letter for this account — e.g. for
    # marketplace seller verification (known value: "AMAZON"; other
    # marketplace-specific values likely exist).
    #
    # @param params [Hash] account_statement_type: (e.g. "AMAZON"),
    #   registration_info: { agreement:, registered_name:, registered_email:,
    #   registered_address: { address:, city:, state:, postcode:, country: } }
    # @return [Hash] symbolized response (the generated letter/document reference)
    def generate_statement_letter(params = {})
      self.class.symbolized_post("#{self.class.resource_path}/#{id}/generate_statement_letter", params)
    end

    # List inbound transactions (deposits) received into this account
    #
    # @param params [Hash] additional query params (e.g. pagination)
    # @return [ListObject<GlobalAccountTransaction>] list of transactions
    def transactions(params = {})
      response = Airwallex.client.get("#{self.class.resource_path}/#{id}/transactions", params)
      build_list(response, GlobalAccountTransaction, params)
    end

    # Create an alias (e.g. PayID, email, or phone-linked VAN) on this account
    #
    # @param params [Hash] alias attributes
    # @return [GlobalAccountAlias]
    def create_alias(params = {})
      response = Airwallex.client.post("#{GlobalAccountAlias.resource_path(id)}/create", params)
      GlobalAccountAlias.new(response)
    end

    # Retrieve a single alias on this account
    #
    # @param alias_id [String]
    # @return [GlobalAccountAlias]
    def alias(alias_id)
      response = Airwallex.client.get("#{GlobalAccountAlias.resource_path(id)}/#{alias_id}")
      GlobalAccountAlias.new(response)
    end

    # List aliases on this account
    #
    # @param params [Hash] additional query params (e.g. pagination)
    # @return [ListObject<GlobalAccountAlias>] list of aliases
    def aliases(params = {})
      response = Airwallex.client.get(GlobalAccountAlias.resource_path(id), params)
      build_list(response, GlobalAccountAlias, params)
    end

    # Retrieve a single direct debit mandate on this account
    #
    # @param mandate_id [String]
    # @return [GlobalAccountMandate]
    def mandate(mandate_id)
      response = Airwallex.client.get("#{GlobalAccountMandate.resource_path(id)}/#{mandate_id}")
      GlobalAccountMandate.new(response)
    end

    # List direct debit mandates on this account
    #
    # @param params [Hash] additional query params (e.g. pagination)
    # @return [ListObject<GlobalAccountMandate>] list of mandates
    def mandates(params = {})
      response = Airwallex.client.get(GlobalAccountMandate.resource_path(id), params)
      build_list(response, GlobalAccountMandate, params)
    end

    private

    def build_list(response, resource_class, params)
      ListObject.new(
        data: extract_items(response),
        has_more: extract_has_more(response),
        next_cursor: extract_next_cursor(response),
        resource_class: resource_class,
        params: params
      )
    end

    def extract_items(response)
      return response if response.is_a?(Array)

      response[:items] || response["items"] || response[:data] || response["data"] || []
    end

    def extract_has_more(response)
      return false unless response.is_a?(Hash)

      response[:has_more] || response["has_more"] || false
    end

    def extract_next_cursor(response)
      return nil unless response.is_a?(Hash)

      response[:next_cursor] || response["next_cursor"]
    end
  end
end
