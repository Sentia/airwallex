# frozen_string_literal: true

module Airwallex
  # Represents a Charge (Scale product) — funds attributed to a Connected
  # Account, tracked before payout.
  #
  # @example Retrieve a charge
  #   charge = Airwallex::Charge.retrieve("chg_123")
  class Charge < APIResource
    extend APIOperations::Create
    extend APIOperations::Retrieve
    extend APIOperations::List

    # @return [String] API resource path for charges
    def self.resource_path
      "/api/v1/charges"
    end
  end
end
