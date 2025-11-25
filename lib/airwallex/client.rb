# frozen_string_literal: true

require "faraday"
require "faraday/multipart"
require "faraday/retry"
require "json"

module Airwallex
  class Client
    attr_reader :config, :access_token, :token_expires_at

    def initialize(config = Airwallex.configuration)
      @config = config
      @config.validate!
      @access_token = nil
      @token_expires_at = nil
      @token_mutex = Mutex.new
    end

    def connection
      @connection ||= Faraday.new(url: config.api_url) do |conn|
        conn.request :json
        conn.request :multipart
        conn.request :retry, retry_options
        conn.response :json, content_type: /\bjson$/
        conn.response :logger, config.logger, { headers: true, bodies: true } if config.logger

        conn.headers["Content-Type"] = "application/json"
        conn.headers["User-Agent"] = user_agent
        conn.headers["x-api-version"] = config.api_version

        conn.adapter Faraday.default_adapter
      end
    end

    def get(path, params = {}, headers = {})
      request(:get, path, params, headers)
    end

    def post(path, body = {}, headers = {})
      request(:post, path, body, headers)
    end

    def put(path, body = {}, headers = {})
      request(:put, path, body, headers)
    end

    def patch(path, body = {}, headers = {})
      request(:patch, path, body, headers)
    end

    def delete(path, params = {}, headers = {})
      request(:delete, path, params, headers)
    end

    def authenticate!
      @token_mutex.synchronize do
        response = connection.post("/api/v1/authentication/login") do |req|
          req.headers["x-client-id"] = config.client_id
          req.headers["x-api-key"] = config.api_key
          req.headers.delete("Authorization")
        end

        handle_response_errors(response)

        data = response.body
        @access_token = data["token"]
        @token_expires_at = Time.now + 1800 # 30 minutes

        @access_token
      end
    end

    def token_expired?
      return true if access_token.nil? || token_expires_at.nil?

      # Refresh if token expires in less than 5 minutes
      Time.now >= (token_expires_at - 300)
    end

    def ensure_authenticated!
      authenticate! if token_expired?
    end

    private

    def request(method, path, data, headers)
      ensure_authenticated!

      response = connection.public_send(method) do |req|
        req.url(path)
        req.headers.merge!(headers)
        req.headers["Authorization"] = "Bearer #{access_token}"

        case method
        when :get, :delete
          req.params = data
        when :post, :put, :patch
          req.body = data
        end
      end

      handle_response_errors(response)
      response.body
    end

    def handle_response_errors(response)
      return if response.success?

      raise Error.from_response(response)
    end

    def retry_options
      {
        max: 3,
        interval: 0.5,
        interval_randomness: 0.5,
        backoff_factor: 2,
        methods: %i[get delete],
        exceptions: [
          Faraday::TimeoutError,
          Faraday::ConnectionFailed
        ],
        retry_statuses: [429, 500, 502, 503, 504]
      }
    end

    def user_agent
      "Airwallex-Ruby/#{Airwallex::VERSION} Ruby/#{RUBY_VERSION}"
    end
  end
end
