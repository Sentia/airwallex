# frozen_string_literal: true

require_relative "airwallex/version"
require_relative "airwallex/errors"
require_relative "airwallex/configuration"
require_relative "airwallex/util"
require_relative "airwallex/client"
require_relative "airwallex/webhook"
require_relative "airwallex/middleware/idempotency"
require_relative "airwallex/middleware/auth_refresh"

module Airwallex
  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def client
      @client ||= Client.new(configuration)
    end

    def reset!
      @configuration = Configuration.new
      @client = nil
    end
  end
end
