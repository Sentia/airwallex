# frozen_string_literal: true

module Airwallex
  # Represents a Billing product — the thing being sold on a subscription
  # (distinct from Payment Acceptance's Customer/PaymentMethod resources).
  #
  # @example Create a product
  #   product = Airwallex::BillingProduct.create(name: "Instalment Plan")
  #
  # @example Update a product
  #   product.update(name: "Instalment Plan (v2)")
  class BillingProduct < APIResource
    extend APIOperations::Create
    extend APIOperations::Retrieve
    extend APIOperations::List
    include APIOperations::Update

    # @return [String] API resource path for billing products
    def self.resource_path
      "/api/v1/billing/products"
    end
  end
end
