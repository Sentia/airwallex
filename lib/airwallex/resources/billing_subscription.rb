# frozen_string_literal: true

module Airwallex
  # Represents a Billing subscription, e.g. a multi-part instalment plan.
  #
  # @example Create a subscription with a deferred start date
  #   # Flat payload, no wrapper key. Prices attach via an items: array of
  #   # { price_id:, quantity: }, not a flat price_id. legal_entity_id comes
  #   # from ConnectedAccount#legal_entity_id, not a separate resource.
  #   # payment_source_id references a PaymentSource (see
  #   # Airwallex::PaymentSource for the full consent -> source -> subscription
  #   # chain), not a PaymentConsent directly.
  #   connected_account = Airwallex::ConnectedAccount.retrieve("acct_123")
  #   subscription = Airwallex::BillingSubscription.create(
  #     billing_customer_id: billing_customer.id,
  #     currency: "AUD",
  #     collection_method: "AUTO_CHARGE",
  #     legal_entity_id: connected_account.legal_entity_id,
  #     payment_source_id: payment_source.id,
  #     starts_at: "2026-09-01T00:00:00+1000",
  #     items: [{ price_id: price.id, quantity: 1 }]
  #   )
  #   subscription.status #=> "PENDING"
  #
  # @example Cancel a subscription
  #   subscription.cancel
  class BillingSubscription < APIResource
    extend APIOperations::Create
    extend APIOperations::Retrieve
    extend APIOperations::List
    include APIOperations::Update

    # @return [String] API resource path for billing subscriptions
    def self.resource_path
      "/api/v1/billing/subscriptions"
    end

    # Cancel this subscription
    #
    # @param params [Hash] additional cancellation params
    # @return [BillingSubscription] self
    def cancel(params = {})
      response = Airwallex.client.post("#{self.class.resource_path}/#{id}/cancel", params)
      refresh_from(response)
      self
    end

    # List the line items on this subscription
    #
    # @param params [Hash] additional query params (e.g. pagination)
    # @return [ListObject<BillingSubscriptionItem>] list of subscription items
    def items(params = {})
      response = Airwallex.client.get("#{self.class.resource_path}/#{id}/items", params)

      ListObject.new(
        data: extract_item_rows(response),
        has_more: extract_has_more(response),
        next_cursor: extract_next_cursor(response),
        resource_class: BillingSubscriptionItem,
        params: params
      )
    end

    # Retrieve a single line item on this subscription
    #
    # @param item_id [String] the subscription item id
    # @return [BillingSubscriptionItem]
    def item(item_id)
      response = Airwallex.client.get("#{self.class.resource_path}/#{id}/items/#{item_id}")
      BillingSubscriptionItem.new(response)
    end

    private

    def extract_item_rows(response)
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
