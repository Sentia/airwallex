# frozen_string_literal: true

module Airwallex
  # Represents an in-person (POS) Terminal used for card-present payments.
  #
  # This gem currently only implements the sandbox Simulation endpoints for
  # driving a terminal through a test payment; it does not yet implement the
  # live terminal create/retrieve/list endpoints.
  # See https://www.airwallex.com/docs/api/simulation/pos-terminals
  #
  # @example Simulate a terminal completing a PaymentIntent
  #   Airwallex::POSTerminal.simulate_turn_on(terminal_id: "term_123")
  #   Airwallex::POSTerminal.simulate_confirm_payment_intent(
  #     terminal_id: "term_123",
  #     payment_scenario_name: "approve"
  #   )
  class POSTerminal < APIResource
    # @return [String] API resource path for simulated POS terminal actions
    def self.resource_path
      "/api/v1/simulation/pa/pos/terminals"
    end

    # Simulate turning a terminal on
    #
    # @param terminal_id [String]
    # @return [POSTerminal]
    def self.simulate_turn_on(terminal_id:)
      response = Airwallex.client.post("#{resource_path}/turn_on", terminal_id: terminal_id)
      new(response)
    end

    # Simulate turning a terminal off
    #
    # @param terminal_id [String]
    # @return [POSTerminal]
    def self.simulate_turn_off(terminal_id:)
      response = Airwallex.client.post("#{resource_path}/turn_off", terminal_id: terminal_id)
      new(response)
    end

    # Simulate generating a terminal activation code
    #
    # @param request_id [String]
    # @return [Hash] raw response (contains the generated activation code)
    def self.simulate_generate_activation_code(request_id:)
      Airwallex.client.post("#{resource_path}/generate_activation_code", request_id: request_id)
    end

    # Simulate a terminal confirming a PaymentIntent under a named test
    # scenario (see .simulate_payment_scenarios for valid names)
    #
    # @param terminal_id [String]
    # @param payment_scenario_name [String]
    # @return [POSTerminal]
    def self.simulate_confirm_payment_intent(terminal_id:, payment_scenario_name:)
      response = Airwallex.client.post(
        "#{resource_path}/confirm_payment_intent",
        terminal_id: terminal_id,
        payment_scenario_name: payment_scenario_name
      )
      new(response)
    end

    # List the test scenario names available to .simulate_confirm_payment_intent
    #
    # @return [Array, Hash] raw response
    def self.simulate_payment_scenarios
      Airwallex.client.get("#{resource_path}/payment_scenarios")
    end
  end
end
