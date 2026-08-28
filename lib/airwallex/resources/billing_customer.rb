# frozen_string_literal: true

module Airwallex
  # Represents a Billing customer — the entity a BillingSubscription is
  # scoped to. Distinct from Airwallex::Customer, which belongs to Payment
  # Acceptance (/api/v1/pa/customers), not Billing.
  #
  # @example Create a billing customer
  #   # Flat payload, no wrapper key (unlike Beneficiary/ConnectedAccount).
  #   # type is "INDIVIDUAL" or "BUSINESS". default_legal_entity_id is not a
  #   # separate resource — it's account_details.legal_entity_id from a
  #   # ConnectedAccount's own retrieve response (see
  #   # ConnectedAccount#legal_entity_id).
  #   connected_account = Airwallex::ConnectedAccount.retrieve("acct_123")
  #   billing_customer = Airwallex::BillingCustomer.create(
  #     name: "Acme Corp",
  #     email: "billing@acme.example",
  #     type: "BUSINESS",
  #     default_billing_currency: "AUD",
  #     default_legal_entity_id: connected_account.legal_entity_id,
  #     address: {
  #       street: "200 Collins Street",
  #       city: "Melbourne",
  #       state: "VIC",
  #       postcode: "3000",
  #       country_code: "AU"
  #     }
  #   )
  class BillingCustomer < APIResource
    extend APIOperations::Create
    extend APIOperations::Retrieve
    extend APIOperations::List
    include APIOperations::Update

    # @return [String] API resource path for billing customers
    def self.resource_path
      "/api/v1/billing/billing_customers"
    end

    # Retrieve the bank transfer instructions for funding this customer's
    # subscriptions (e.g. for a BT-funded instalment plan).
    #
    # @return [Hash] raw bank transfer instructions
    def bank_transfer_instructions
      Airwallex.client.get("#{self.class.resource_path}/#{id}/bank_transfer_instructions")
    end
  end
end
