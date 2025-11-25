# frozen_string_literal: true

module Airwallex
  # Balance resource for account balance queries
  #
  # Query account balances across all currencies or for specific currencies.
  # Shows available, pending, and reserved amounts.
  #
  # @example Get all balances
  #   balances = Airwallex::Balance.list
  #   balances.each do |balance|
  #     puts "#{balance.currency}: #{balance.available_amount}"
  #   end
  #
  # @example Get specific currency balance
  #   usd_balance = Airwallex::Balance.retrieve('USD')
  #   puts "Available: #{usd_balance.available_amount}"
  #   puts "Pending: #{usd_balance.pending_amount}"
  #   puts "Reserved: #{usd_balance.reserved_amount}"
  #
  class Balance < APIResource
    extend APIOperations::List

    def self.resource_path
      "/api/v1/balances/current"
    end

    # Retrieve balance for a specific currency
    #
    # @param currency [String] Currency code (e.g., 'USD', 'EUR')
    # @return [Airwallex::Balance] Balance object for the currency
    def self.retrieve(currency)
      response = Airwallex.client.get(resource_path, currency: currency)
      # Balance API returns array directly at top level
      balances_array = response.is_a?(Array) ? response : response[:data] || response["data"] || []
      balances = ListObject.new(
        data: balances_array,
        has_more: false,
        resource_class: self
      )

      # Filter to find the requested currency
      balance = balances.find { |b| b.currency&.upcase == currency.upcase }
      raise NotFoundError, "Balance not found for currency: #{currency}" unless balance

      balance
    end

    # Calculate total balance
    #
    # @return [Float] Sum of available, pending, and reserved amounts
    def total_amount
      available = respond_to?(:available_amount) ? available_amount.to_f : 0.0
      pending = respond_to?(:pending_amount) ? pending_amount.to_f : 0.0
      reserved = respond_to?(:reserved_amount) ? reserved_amount.to_f : 0.0
      (available + pending + reserved).round(2)
    end
  end
end
