# frozen_string_literal: true

module Airwallex
  # Quote resource for locked exchange rates
  #
  # Create quotes to lock exchange rates for a short period (typically 30-60 seconds).
  # Use quotes to guarantee the rate when executing conversions.
  #
  # @example Create a quote
  #   quote = Airwallex::Quote.create(
  #     buy_currency: 'EUR',
  #     sell_currency: 'USD',
  #     sell_amount: 1000.00
  #   )
  #   puts "Locked rate: #{quote.client_rate}, expires: #{quote.expires_at}"
  #
  # @example Use quote for conversion
  #   conversion = Airwallex::Conversion.create(quote_id: quote.id)
  #
  class Quote < APIResource
    extend APIOperations::Create
    extend APIOperations::Retrieve

    def self.resource_path
      "/api/v1/fx/quotes"
    end

    # Check if quote has expired
    #
    # @return [Boolean] true if quote is expired
    def expired?
      return false unless respond_to?(:expires_at) && expires_at

      Time.parse(expires_at) < Time.now
    rescue ArgumentError
      true
    end

    # Get seconds until expiration
    #
    # @return [Integer, nil] seconds remaining, 0 if expired, nil if no expiration
    def seconds_until_expiration
      return nil unless respond_to?(:expires_at) && expires_at

      remaining = Time.parse(expires_at) - Time.now
      [remaining.to_i, 0].max
    rescue ArgumentError
      0
    end
  end
end
