# frozen_string_literal: true

module Airwallex
  class Client
    module Logging
      private

      # Log requests/responses with credentials masked: the API key header,
      # the bearer token, and the token in the login response body
      def configure_logger(conn, bodies:)
        return unless config.logger

        conn.response :logger, config.logger, { headers: true, bodies: bodies } do |logger|
          logger.filter(/(x-api-key: )"[^"]*"/i, '\1"[FILTERED]"')
          logger.filter(/(Authorization: )"Bearer [^"]*"/i, '\1"Bearer [FILTERED]"')
          logger.filter(/("token":\s*)"[^"]*"/, '\1"[FILTERED]"')
        end
      end
    end
  end
end
