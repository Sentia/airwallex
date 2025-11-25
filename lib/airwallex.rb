# frozen_string_literal: true

require_relative "airwallex/version"
require_relative "airwallex/errors"
require_relative "airwallex/configuration"
require_relative "airwallex/util"
require_relative "airwallex/client"
require_relative "airwallex/webhook"
require_relative "airwallex/middleware/idempotency"
require_relative "airwallex/middleware/auth_refresh"

# API Operations
require_relative "airwallex/api_operations/create"
require_relative "airwallex/api_operations/retrieve"
require_relative "airwallex/api_operations/list"
require_relative "airwallex/api_operations/update"
require_relative "airwallex/api_operations/delete"

# Core classes
require_relative "airwallex/list_object"
require_relative "airwallex/api_resource"

# Resources
require_relative "airwallex/resources/payment_intent"
require_relative "airwallex/resources/transfer"
require_relative "airwallex/resources/beneficiary"
require_relative "airwallex/resources/refund"
require_relative "airwallex/resources/payment_method"
require_relative "airwallex/resources/customer"
require_relative "airwallex/resources/batch_transfer"
require_relative "airwallex/resources/dispute"

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
