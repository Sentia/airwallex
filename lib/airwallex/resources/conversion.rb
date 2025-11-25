# frozen_string_literal: true

module Airwallex
  # Conversion resource for currency exchange
  #
  # Execute currency conversions with locked quotes or at market rates.
  # Conversions move funds between currency balances in your account.
  #
  # @example Convert with locked quote
  #   quote = Airwallex::Quote.create(
  #     buy_currency: 'EUR',
  #     sell_currency: 'USD',
  #     sell_amount: 1000.00
  #   )
  #   conversion = Airwallex::Conversion.create(
  #     quote_id: quote.id,
  #     request_id: "conv_#{Time.now.to_i}"
  #   )
  #
  # @example Convert at market rate
  #   conversion = Airwallex::Conversion.create(
  #     buy_currency: 'EUR',
  #     sell_currency: 'USD',
  #     sell_amount: 500.00,
  #     request_id: "conv_#{Time.now.to_i}"
  #   )
  #
  # @example List conversion history
  #   conversions = Airwallex::Conversion.list(
  #     sell_currency: 'USD',
  #     status: 'COMPLETED'
  #   )
  #
  class Conversion < APIResource
    extend APIOperations::Create
    extend APIOperations::Retrieve
    extend APIOperations::List

    def self.resource_path
      "/api/v1/conversions"
    end
  end
end
