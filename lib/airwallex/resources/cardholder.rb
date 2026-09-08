# frozen_string_literal: true

module Airwallex
  # Represents an Issuing Cardholder.
  #
  # This gem currently only implements the sandbox Simulation endpoint for
  # bypassing a cardholder's RFI review stage; it does not yet implement the
  # live create/retrieve/list endpoints.
  # See https://www.airwallex.com/docs/api/simulation/issuing-cardholders
  #
  # @example Bypass a cardholder's pending review
  #   Airwallex::Cardholder.simulate_pass_review("chd_123")
  class Cardholder < APIResource
    # @return [String] API resource path for simulated cardholder actions
    def self.resource_path
      "/api/v1/simulation/issuing/cardholders"
    end

    # Simulate bypassing this cardholder's RFI review stage
    #
    # @param cardholder_id [String]
    # @return [Cardholder]
    def self.simulate_pass_review(cardholder_id)
      response = Airwallex.client.post("#{resource_path}/#{cardholder_id}/pass_review", {})
      new(response)
    end
  end
end
