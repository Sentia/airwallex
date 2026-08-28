# frozen_string_literal: true

module Airwallex
  # Represents a Billing Payment Source — the object a BillingSubscription's
  # payment_source_id actually references. NOT the same object as
  # PaymentConsent (/pa/payment_consents).
  #
  # external_id is the id of a PaymentMethod (/pa/payment_methods), not a
  # PaymentConsent's own id. The PaymentConsent is still part of the flow —
  # it's what authorizes that PaymentMethod for merchant-initiated
  # (unscheduled) charges — but the id PaymentSource wants is the underlying
  # PaymentMethod's.
  #
  # @example Full flow: PaymentMethod -> PaymentConsent -> PaymentSource -> BillingSubscription
  #   payment_method = Airwallex::PaymentMethod.create(
  #     customer_id: customer.id,
  #     type: "card",
  #     card: { ... } # a real test card in sandbox
  #   )
  #
  #   consent = Airwallex::PaymentConsent.create(
  #     customer_id: customer.id,
  #     payment_method: { id: payment_method.id },
  #     next_triggered_by: "merchant",
  #     merchant_trigger_reason: "unscheduled"
  #   )
  #   consent.verify(...)
  #
  #   source = Airwallex::PaymentSource.create(
  #     billing_customer_id: billing_customer.id,
  #     external_id: payment_method.id,
  #     linked_payment_account_id: connected_account.id
  #   )
  #
  #   Airwallex::BillingSubscription.create(
  #     billing_customer_id: billing_customer.id,
  #     legal_entity_id: connected_account.legal_entity_id,
  #     collection_method: "AUTO_CHARGE",
  #     payment_source_id: source.id,
  #     items: [{ price_id: price.id, quantity: 1 }]
  #   )
  class PaymentSource < APIResource
    extend APIOperations::Create
    extend APIOperations::Retrieve
    extend APIOperations::List

    # @return [String] API resource path for billing payment sources
    def self.resource_path
      "/api/v1/billing/payment_sources"
    end
  end
end
