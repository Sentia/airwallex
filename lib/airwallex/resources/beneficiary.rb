# frozen_string_literal: true

module Airwallex
  # @example Create a beneficiary
  #   # nickname/payer_entity_type/transfer_methods are top-level siblings of
  #   # `beneficiary`, not nested inside it. request_id is optional (the
  #   # gem's Idempotency middleware injects one automatically). Call
  #   # .api_schema / .form_schema for the exact required fields per
  #   # entity_type + bank_country_code.
  #   beneficiary = Airwallex::Beneficiary.create(
  #     nickname: "Acme Corp",
  #     payer_entity_type: "COMPANY",
  #     transfer_methods: ["LOCAL"],
  #     beneficiary: {
  #       entity_type: "COMPANY",
  #       company_name: "Acme Corp",
  #       address: {
  #         country_code: "AU",
  #         city: "Melbourne",
  #         state: "VIC",
  #         postcode: "3000",
  #         street_address: "15 William Street"
  #       },
  #       bank_details: {
  #         account_name: "Acme Corp",
  #         account_number: "12750852",
  #         account_currency: "AUD",
  #         bank_country_code: "AU",
  #         bank_name: "National Australia Bank",
  #         account_routing_type1: "bsb",
  #         account_routing_value1: "083064",
  #         local_clearing_system: "BANK_TRANSFER" # country-specific enum
  #       }
  #     }
  #   )
  #
  # @example Update a beneficiary
  #   # .update doesn't support a partial patch — resend the full payload
  #   # with your change merged in.
  #   beneficiary.update(
  #     transfer_methods: ["LOCAL"],
  #     beneficiary: {
  #       entity_type: "COMPANY",
  #       company_name: "Acme Corp Ltd",
  #       bank_details: { account_currency: "AUD", bank_country_code: "AU", ... }
  #     }
  #   )
  class Beneficiary < APIResource
    extend APIOperations::Create
    extend APIOperations::Retrieve
    extend APIOperations::List
    extend APIOperations::Delete
    include APIOperations::Update

    API_SCHEMA_PATH = "/api/v1/beneficiary_api_schemas/generate"
    FORM_SCHEMA_PATH = "/api/v1/beneficiary_form_schemas/generate"
    SUPPORTED_FINANCIAL_INSTITUTIONS_PATH = "/api/v1/beneficiary_form_schemas/supported_financial_institutions"

    def self.resource_path
      "/api/v1/beneficiaries"
    end

    # Validate beneficiary details (address, bank details, entity type, transfer
    # method) before attempting to create the beneficiary.
    #
    # @param params [Hash] the same shape of params you'd pass to .create
    # @return [Hash] raw validation result
    def self.validate(params = {})
      Airwallex.client.post("#{resource_path}/validate", params)
    end

    # Verify ownership of a beneficiary's bank account via Confirmation of
    # Payee (CoP) before creation.
    #
    # @param params [Hash] beneficiary bank account details to verify
    # @return [Hash] raw verification result (status, account_name_match_result)
    def self.verify_account(params = {})
      Airwallex.client.post("#{resource_path}/verify_account", params)
    end

    # Retrieve the API schema (field validation rules) for beneficiary bank
    # details, keyed by beneficiary type / entity type / bank country.
    #
    # @param params [Hash] e.g. beneficiary_type:, bank_country_code:
    # @return [Hash] raw schema response
    def self.api_schema(params = {})
      Airwallex.client.post(API_SCHEMA_PATH, params)
    end

    # Retrieve the dynamic form schema used to render beneficiary bank-detail
    # forms in the UI, keyed by beneficiary type / entity type / bank country.
    #
    # @param params [Hash] e.g. beneficiary_type:, bank_country_code:
    # @return [Hash] raw schema response
    def self.form_schema(params = {})
      Airwallex.client.post(FORM_SCHEMA_PATH, params)
    end

    # Search financial institutions supported for a given country, currency,
    # entity type, and transfer method, by name keyword.
    #
    # @param params [Hash] required: bank_country_code:, account_currency:,
    #   entity_type:, transfer_method:, keyword: (a bank-name search term,
    #   min 3 chars)
    # @return [Hash] raw response listing supported institutions
    def self.supported_financial_institutions(params = {})
      Airwallex.client.get(SUPPORTED_FINANCIAL_INSTITUTIONS_PATH, params)
    end
  end
end
