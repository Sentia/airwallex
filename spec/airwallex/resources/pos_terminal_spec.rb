# frozen_string_literal: true

require "spec_helper"

RSpec.describe Airwallex::POSTerminal do
  describe ".simulate_turn_on" do
    it "turns a terminal on" do
      stub_request(:post, "#{BASE_URL}/api/v1/simulation/pa/pos/terminals/turn_on")
        .with(body: hash_including(terminal_id: "term_123"))
        .to_return(
          status: 200,
          body: { terminal_id: "term_123", status: "ONLINE" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      terminal = described_class.simulate_turn_on(terminal_id: "term_123")

      expect(terminal.status).to eq("ONLINE")
    end
  end

  describe ".simulate_turn_off" do
    it "turns a terminal off" do
      stub_request(:post, "#{BASE_URL}/api/v1/simulation/pa/pos/terminals/turn_off")
        .with(body: hash_including(terminal_id: "term_123"))
        .to_return(
          status: 200,
          body: { terminal_id: "term_123", status: "OFFLINE" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      terminal = described_class.simulate_turn_off(terminal_id: "term_123")

      expect(terminal.status).to eq("OFFLINE")
    end
  end

  describe ".simulate_generate_activation_code" do
    it "generates a terminal activation code" do
      stub_request(:post, "#{BASE_URL}/api/v1/simulation/pa/pos/terminals/generate_activation_code")
        .with(body: hash_including(request_id: "req_123"))
        .to_return(
          status: 200,
          body: { activation_code: "123456" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      response = described_class.simulate_generate_activation_code(request_id: "req_123")

      expect(response["activation_code"]).to eq("123456")
    end
  end

  describe ".simulate_confirm_payment_intent" do
    it "confirms a payment intent under a named scenario" do
      stub_request(:post, "#{BASE_URL}/api/v1/simulation/pa/pos/terminals/confirm_payment_intent")
        .with(body: hash_including(terminal_id: "term_123", payment_scenario_name: "approve"))
        .to_return(
          status: 200,
          body: { terminal_id: "term_123", payment_scenario_name: "approve" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      terminal = described_class.simulate_confirm_payment_intent(
        terminal_id: "term_123",
        payment_scenario_name: "approve"
      )

      expect(terminal.payment_scenario_name).to eq("approve")
    end
  end

  describe ".simulate_payment_scenarios" do
    it "lists available test scenario names" do
      stub_request(:get, "#{BASE_URL}/api/v1/simulation/pa/pos/terminals/payment_scenarios")
        .to_return(
          status: 200,
          body: %w[approve decline].to_json,
          headers: { "Content-Type" => "application/json" }
        )

      response = described_class.simulate_payment_scenarios

      expect(response).to eq(%w[approve decline])
    end
  end
end
