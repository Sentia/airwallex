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
  # There is no .list — /fx/rates/current always returns the rate for one
  # specific currency pair, not a collection.
  class Rate < APIResource
    extend APIOperations::Retrieve

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
