# frozen_string_literal: true

require "openssl"

module Airwallex
  module Webhook
    DEFAULT_TOLERANCE = 300 # 5 minutes

    module_function

    def construct_event(payload, signature, timestamp, secret:, tolerance: DEFAULT_TOLERANCE)
      verify_signature(payload, signature, timestamp, secret, tolerance)

      data = JSON.parse(payload)
      Event.new(data)
    rescue JSON::ParserError => e
      raise SignatureVerificationError, "Invalid payload: #{e.message}"
    end

    def verify_signature(payload, signature, timestamp, secret, tolerance)
      verify_timestamp(timestamp, tolerance)

      expected_signature = compute_signature(timestamp, payload, secret)

      unless secure_compare(expected_signature, signature)
        raise SignatureVerificationError, "Signature verification failed"
      end

      true
    end

    def compute_signature(timestamp, payload, secret)
      data = "#{timestamp}#{payload}"
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), secret, data)
    end

    def verify_timestamp(timestamp, tolerance)
      current_time = Time.now.to_i
      timestamp_int = timestamp.to_i

      if (current_time - timestamp_int).abs > tolerance
        raise SignatureVerificationError, "Timestamp outside tolerance (#{tolerance}s)"
      end

      true
    end

    def secure_compare(a, b)
      return false if a.nil? || b.nil? || a.bytesize != b.bytesize

      OpenSSL.fixed_length_secure_compare(a, b)
    end

    private_class_method :compute_signature, :verify_timestamp, :secure_compare

    class Event
      attr_reader :id, :type, :data, :created_at

      def initialize(attributes = {})
        @id = attributes["id"]
        @type = attributes["type"]
        @data = attributes["data"]
        @created_at = attributes["created_at"]
      end
    end
  end
end
