# frozen_string_literal: true

module Airwallex
  class Error < StandardError
    # @return [String, nil] error code
    # @return [String, nil] param the offending field path, from the response's `source`
    # @return [Hash, Array, nil] details symbolized field-level error detail, e.g. from a
    #   validation_failed response (was raw/string-keyed prior to 0.8.0)
    # @return [Integer, nil] http_status
    attr_reader :code, :message, :param, :details, :http_status

    def initialize(message = nil, code: nil, param: nil, details: nil, http_status: nil)
      @code = code
      @message = message
      @param = param
      @details = Util.deep_symbolize_keys(details)
      @http_status = http_status
      super(message)
    end

    def self.from_response(response)
      body = parse_body(response.body)
      status = response.status

      error_class = error_class_for_status(status)
      error_class.new(
        body["message"],
        code: body["code"],
        param: body["source"],
        details: body["details"],
        http_status: status
      )
    end

    def self.parse_body(body)
      return {} if body.nil? || body.empty?
      return body if body.is_a?(Hash)

      JSON.parse(body)
    rescue JSON::ParserError
      { "message" => body }
    end

    def self.error_class_for_status(status)
      case status
      when 400 then BadRequestError
      when 401 then AuthenticationError
      when 403 then PermissionError
      when 404 then NotFoundError
      when 429 then RateLimitError
      when 500..599 then APIError
      else Error
      end
    end

    private_class_method :parse_body, :error_class_for_status
  end

  class ConfigurationError < Error; end
  class BadRequestError < Error; end
  class AuthenticationError < Error; end
  class PermissionError < Error; end
  class NotFoundError < Error; end
  class RateLimitError < Error; end
  class APIError < Error; end
  class InsufficientFundsError < Error; end
  class QuoteExpiredError < BadRequestError; end
  class SCARequiredError < PermissionError; end
  class SignatureVerificationError < Error; end
end
