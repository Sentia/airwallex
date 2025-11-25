# frozen_string_literal: true

module Airwallex
  class Transfer < APIResource
    extend APIOperations::Create
    extend APIOperations::Retrieve
    extend APIOperations::List

    def self.resource_path
      "/api/v1/transfers"
    end

    # Cancel a pending transfer
    def cancel
      response = Airwallex.client.post(
        "#{self.class.resource_path}/#{id}/cancel",
        {}
      )
      refresh_from(response)
      self
    end
  end
end
