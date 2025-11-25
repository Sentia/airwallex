# frozen_string_literal: true

module Airwallex
  class Configuration
    attr_accessor :api_key, :client_id, :api_version, :logger, :log_level
    attr_reader :environment

    SANDBOX_API_URL = "https://api-demo.airwallex.com/api/v1"
    PRODUCTION_API_URL = "https://api.airwallex.com/api/v1"
    SANDBOX_FILES_URL = "https://files-demo.airwallex.com"
    PRODUCTION_FILES_URL = "https://files.airwallex.com"

    DEFAULT_API_VERSION = "2024-09-27"
    VALID_ENVIRONMENTS = %i[sandbox production].freeze

    def initialize
      @environment = :sandbox
      @api_version = DEFAULT_API_VERSION
      @log_level = :info
    end

    def api_url
      case environment
      when :sandbox
        SANDBOX_API_URL
      when :production
        PRODUCTION_API_URL
      else
        raise ConfigurationError, "Invalid environment: #{environment}. Must be :sandbox or :production"
      end
    end

    def files_url
      case environment
      when :sandbox
        SANDBOX_FILES_URL
      when :production
        PRODUCTION_FILES_URL
      else
        raise ConfigurationError, "Invalid environment: #{environment}. Must be :sandbox or :production"
      end
    end

    def environment=(env)
      unless VALID_ENVIRONMENTS.include?(env)
        raise ConfigurationError, "Invalid environment: #{env}. Must be one of #{VALID_ENVIRONMENTS.join(", ")}"
      end

      @environment = env
    end

    def validate!
      errors = []
      errors << "api_key is required" if api_key.nil? || api_key.empty?
      errors << "client_id is required" if client_id.nil? || client_id.empty?
      errors << "environment must be :sandbox or :production" unless VALID_ENVIRONMENTS.include?(environment)

      raise ConfigurationError, errors.join(", ") unless errors.empty?

      true
    end

    def configured?
      !api_key.nil? && !client_id.nil? && VALID_ENVIRONMENTS.include?(environment)
    end
  end
end
