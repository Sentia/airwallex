# frozen_string_literal: true

module Airwallex
  # Rate resource for real-time exchange rates
  #
  # Get indicative exchange rates for currency pairs.
  # Rates are real-time but not locked - use Quote for guaranteed rates.
  #
  # @example Get current rate
  #   rate = Airwallex::Rate.retrieve(buy_currency: 'EUR', sell_currency: 'USD')
  #   puts "1 USD = #{rate.client_rate} EUR"
  #
  # @example Get multiple rates (Note: API may not support multiple at once)
  #   rate = Airwallex::Rate.retrieve(
  #     buy_currency: 'EUR',
  #     sell_currency: 'USD'
  #   )
  #
  class Rate < APIResource
    extend APIOperations::Retrieve
    extend APIOperations::List

    def self.resource_path
      "/api/v1/fx/rates/current"
    end

    # Override retrieve to handle query parameters instead of ID
    def self.retrieve(params = {})
      response = Airwallex.client.get(resource_path, params)
      new(response)
    end
  end
end
