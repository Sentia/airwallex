# frozen_string_literal: true

module Airwallex
  # Represents a Billing price — the amount/currency/cadence attached to a
  # BillingProduct that a BillingSubscription is created against.
  #
  # @example Create a simple per-unit recurring price
  #   # Flat payload, no wrapper key. pricing_model is required (PER_UNIT /
  #   # FLAT / GRADUATED / VOLUME — GRADUATED uses tiers: instead of
  #   # unit_amount:). recurring: is what makes a price usable for a
  #   # subscription.
  #   price = Airwallex::BillingPrice.create(
  #     product_id: product.id,
  #     currency: "AUD",
  #     pricing_model: "PER_UNIT",
  #     unit_amount: 250.00,
  #     recurring: { period: 1, period_unit: "MONTH" }
  #   )
  class BillingPrice < APIResource
    extend APIOperations::Create
    extend APIOperations::Retrieve
    extend APIOperations::List
    include APIOperations::Update

    # @return [String] API resource path for billing prices
    def self.resource_path
      "/api/v1/billing/prices"
    end
  end
end
