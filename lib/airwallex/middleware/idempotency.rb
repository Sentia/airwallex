# frozen_string_literal: true

module Airwallex
  module Middleware
    class Idempotency < Faraday::Middleware
      IDEMPOTENT_METHODS = %i[post put patch].freeze

      def call(env)
        inject_request_id(env) if idempotent_request?(env)

        @app.call(env)
      end

      private

      def idempotent_request?(env)
        IDEMPOTENT_METHODS.include?(env[:method]) && env[:body].is_a?(Hash)
      end

      def inject_request_id(env)
        body = env[:body]

        return if body.key?("request_id") || body.key?(:request_id)

        body[:request_id] = Airwallex::Util.generate_idempotency_key
      end
    end
  end
end
