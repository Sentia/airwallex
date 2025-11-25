# frozen_string_literal: true

require "securerandom"
require "time"
require "bigdecimal"

module Airwallex
  module Util
    module_function

    def generate_idempotency_key
      SecureRandom.uuid
    end

    def format_date_time(value)
      case value
      when Time, DateTime
        value.utc.iso8601
      when Date
        value.to_time.utc.iso8601
      when String
        value
      else
        raise ArgumentError, "Cannot format #{value.class} as ISO 8601"
      end
    end

    def parse_date_time(value)
      return nil if value.nil?
      return value if value.is_a?(Time)

      Time.iso8601(value)
    rescue ArgumentError
      Time.parse(value)
    end

    def symbolize_keys(hash)
      return hash unless hash.is_a?(Hash)

      hash.transform_keys(&:to_sym)
    end

    def deep_symbolize_keys(hash)
      return hash unless hash.is_a?(Hash)

      hash.each_with_object({}) do |(key, value), result|
        result[key.to_sym] = value.is_a?(Hash) ? deep_symbolize_keys(value) : value
      end
    end

    def to_money(value)
      return value if value.is_a?(BigDecimal)
      return BigDecimal("0") if value.nil?

      BigDecimal(value.to_s)
    end
  end
end
