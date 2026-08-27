# frozen_string_literal: true

module Airwallex
  module Middleware
    class AuthRefresh < Faraday::Middleware
      def initialize(app, client)
        super(app)
        @client = client
      end

      def call(env)
        # Skip authentication entirely for the login endpoint itself
        return @app.call(env) if login_request?(env)

        # Ensure token is valid before making the request, then attach it
        @client.ensure_authenticated! unless authentication_request?(env)
        authorize!(env)

        response = @app.call(env)

        # If we get a 401, try refreshing the token and retrying once
        if response.status == 401
          @client.authenticate!
          authorize!(env)
          response = @app.call(env)
        end

        response
      end

      private

      def login_request?(env)
        env[:url].path.include?(Client::LOGIN_PATH)
      end

      def authentication_request?(env)
        env[:url].path.include?("/authentication/")
      end

      def authorize!(env)
        env[:request_headers]["Authorization"] = "Bearer #{@client.access_token}"
      end
    end
  end
end
