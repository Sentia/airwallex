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

        # Once a response arrives, env[:body] holds the response body, so
        # keep the request body to re-send it (same as faraday-retry)
        request_body = env[:body]
        response = @app.call(env)

        # If we get a 401, try refreshing the token and retrying once
        if response.status == 401
          @client.authenticate!
          authorize!(env)
          env[:body] = request_body
          # A multipart upload body is a stream the first attempt already
          # read; rewind it so the retry sends the file again
          request_body.rewind if request_body.respond_to?(:rewind)
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
