# frozen_string_literal: true

module Airwallex
  class Client
    # Multipart uploads to the files host (config.files_url), which is
    # separate from the main API host
    module FileUploads
      # Separate connection for the files host (config.files_url). It sends
      # multipart bodies, so it deliberately has no JSON Content-Type default,
      # no :json request encoding, and no Idempotency middleware (which would
      # add a stray request_id form field). No :retry either: faraday-retry
      # only retries GET/DELETE here, and uploads are POSTs.
      def files_connection
        @files_connection ||= Faraday.new(url: config.files_url) do |conn|
          conn.request :multipart
          conn.use Airwallex::Middleware::AuthRefresh, self
          conn.response :json, content_type: /\bjson$/
          # Never log bodies here: they're the uploaded file's bytes
          configure_logger(conn, bodies: false)

          conn.headers["User-Agent"] = user_agent
          conn.headers["x-api-version"] = config.api_version if config.api_version

          conn.adapter Faraday.default_adapter
        end
      end

      # POST a multipart upload to the files host
      #
      # @param path [String] e.g. "/api/v1/files/upload"
      # @param file_part [Faraday::Multipart::FilePart] sent as the "file" field
      # @param params [Hash] extra form fields (e.g. notes:)
      # @param headers [Hash] e.g. { "x-on-behalf-of" => account_id }
      # @return [Hash] parsed response body
      def upload(path, file_part, params = {}, headers = {})
        response = files_connection.post(path) do |req|
          req.headers.merge!(headers)
          req.body = { file: file_part }.merge(params)
        end

        handle_response_errors(response)
        response.body
      end
    end
  end
end
