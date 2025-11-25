# frozen_string_literal: true

module Airwallex
  module Middleware
    class AuthRefresh < Faraday::Middleware
      def initialize(app, client)
        super(app)
        @client = client
      end

      def call(env)
        # Skip authentication refresh for login endpoint
        return @app.call(env) if env[:url].path.include?("/authentication/login")

        # Ensure token is valid before making request
        @client.ensure_authenticated! unless env[:url].path.include?("/authentication/")

        response = @app.call(env)

        # If we get a 401, try refreshing the token and retrying once
        if response.status == 401 && !env[:request].fetch(:auth_retry, false)
          @client.authenticate!
          env[:request][:auth_retry] = true
          env[:request_headers]["Authorization"] = "Bearer #{@client.access_token}"
          response = @app.call(env)
        end

        response
      end
    end
  end
end
