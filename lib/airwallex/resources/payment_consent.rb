# frozen_string_literal: true

module Airwallex
  # Represents a Payment Consent — a saved card/payment method authorized for
  # future off-session charges without re-prompting the customer.
  #
  # Does NOT attach directly to a BillingSubscription — a subscription's
  # payment_source_id references a PaymentSource (see Airwallex::PaymentSource),
  # a separate Billing object created FROM a verified, merchant-initiated
  # PaymentConsent. See PaymentSource's docstring for the full chain.
  #
  # @example Create and verify a consent for merchant-initiated (unscheduled) charges
  #   # next_triggered_by/merchant_trigger_reason are required for the
  #   # consent to later be usable to create a PaymentSource.
  #   consent = Airwallex::PaymentConsent.create(
  #     customer_id: customer.id,
  #     payment_method: { type: "card", card: { ... } },
  #     next_triggered_by: "merchant",
  #     merchant_trigger_reason: "unscheduled"
  #   )
  #   consent.verify(payment_method: { card: { cvc: "123" } })
  #
  # @example Disable a consent
  #   consent.disable
  class PaymentConsent < APIResource
    extend APIOperations::Create
    extend APIOperations::Retrieve
    extend APIOperations::List
    include APIOperations::Update

    # @return [String] API resource path for payment consents
    def self.resource_path
      "/api/v1/pa/payment_consents"
    end

    # Verify this consent (e.g. via a zero/low-value authorization) before
    # it can be used for off-session charges
    #
    # @param params [Hash] verification params (e.g. payment_method details)
    # @return [PaymentConsent] self
    def verify(params = {})
      response = Airwallex.client.post("#{self.class.resource_path}/#{id}/verify", params)
      refresh_from(response)
      self
    end

    # Continue a verification that requires further customer action
    # (e.g. completing 3DS)
    #
    # @param params [Hash] continuation params
    # @return [PaymentConsent] self
    def verify_continue(params = {})
      response = Airwallex.client.post("#{self.class.resource_path}/#{id}/verify_continue", params)
      refresh_from(response)
      self
    end

    # Disable this consent so it can no longer be charged
    #
    # @param params [Hash] additional params
    # @return [PaymentConsent] self
    def disable(params = {})
      response = Airwallex.client.post("#{self.class.resource_path}/#{id}/disable", params)
      refresh_from(response)
      self
    end
  end
end
