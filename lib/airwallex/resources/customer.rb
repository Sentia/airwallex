# frozen_string_literal: true

module Airwallex
  # Represents a customer for organizing payment methods and transactions
  #
  # Customers allow you to group payment methods and track payment history
  # for individual users or accounts.
  #
  # @example Create a customer
  #   # merchant_customer_id is required — your own reference id for this
  #   # customer. request_id is optional (the gem's Idempotency middleware
  #   # injects one automatically).
  #   customer = Airwallex::Customer.create(
  #     merchant_customer_id: SecureRandom.uuid,
  #     email: "john@example.com",
  #     first_name: "John",
  #     last_name: "Doe",
  #     phone_number: "+1 1234567890"
  #   )
  #
  # @example List payment methods for a customer
  #   methods = Airwallex::PaymentMethod.list(customer_id: customer.id)
  class Customer < APIResource
    extend APIOperations::Create
    extend APIOperations::Retrieve
    extend APIOperations::List
    include APIOperations::Update
    extend APIOperations::Delete

    # @return [String] API resource path for customers
    def self.resource_path
      "/api/v1/pa/customers"
    end

    # List payment methods for this customer
    #
    # @param params [Hash] additional parameters
    # @return [ListObject<PaymentMethod>] list of payment methods
    def payment_methods(params = {})
      PaymentMethod.list(params.merge(customer_id: id))
    end
  end
end
