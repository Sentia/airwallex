# frozen_string_literal: true

require "spec_helper"

RSpec.describe Airwallex::IssuingTransaction do
  describe ".simulate_create" do
    it "simulates a card authorization" do
      stub_request(:post, "#{BASE_URL}/api/v1/simulation/issuing/create")
        .with(body: hash_including(card_id: "card_123", transaction_amount: 25.0, transaction_currency: "USD"))
        .to_return(
          status: 201,
          body: {
            transaction_id: "txn_123",
            transaction_type: "AUTHORIZATION",
            card_id: "card_123",
            transaction_amount: -25,
            transaction_currency: "USD",
            status: "PENDING"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      txn = described_class.simulate_create(
        card_id: "card_123",
        transaction_amount: 25.0,
        transaction_currency: "USD"
      )

      expect(txn).to be_a(described_class)
      expect(txn.transaction_id).to eq("txn_123")
      expect(txn.status).to eq("PENDING")
    end

    it "supports single_phase authorize-and-clear" do
      stub_request(:post, "#{BASE_URL}/api/v1/simulation/issuing/create")
        .with(body: hash_including(single_phase: true))
        .to_return(
          status: 201,
          body: { transaction_id: "txn_456", transaction_type: "CLEARING", status: "APPROVED" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      txn = described_class.simulate_create(
        card_id: "card_123",
        transaction_amount: 10.0,
        transaction_currency: "USD",
        single_phase: true
      )

      expect(txn.transaction_id).to eq("txn_456")
      expect(txn.status).to eq("APPROVED")
    end
  end

  describe ".simulate_capture" do
    it "captures a pending transaction by transaction id" do
      stub_request(:post, "#{BASE_URL}/api/v1/simulation/issuing/card_transaction_lifecycles/txn_123/capture")
        .to_return(
          status: 200,
          body: { transaction_id: "txn_123", status: "APPROVED" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      txn = described_class.simulate_capture("txn_123")

      expect(txn.status).to eq("APPROVED")
    end

    it "supports a partial capture amount" do
      stub_request(:post, "#{BASE_URL}/api/v1/simulation/issuing/card_transaction_lifecycles/txn_123/capture")
        .with(body: hash_including(transaction_amount: 5.0))
        .to_return(
          status: 200,
          body: { transaction_id: "txn_123" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      described_class.simulate_capture("txn_123", transaction_amount: 5.0)
    end
  end

  describe ".simulate_reverse" do
    it "reverses a pending transaction by transaction id" do
      stub_request(:post, "#{BASE_URL}/api/v1/simulation/issuing/card_transaction_lifecycles/txn_123/reverse")
        .to_return(
          status: 200,
          body: { transaction_id: "txn_123", status: "APPROVED" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      txn = described_class.simulate_reverse("txn_123")

      expect(txn.status).to eq("APPROVED")
    end
  end

  describe ".simulate_refund" do
    it "refunds a captured transaction back to the card" do
      stub_request(:post, "#{BASE_URL}/api/v1/simulation/issuing/refund")
        .with(body: hash_including(card_id: "card_123", transaction_amount: 25.0, transaction_currency: "USD"))
        .to_return(
          status: 200,
          body: { transaction_id: "txn_789", transaction_type: "REFUND", status: "APPROVED" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      txn = described_class.simulate_refund(
        card_id: "card_123",
        transaction_amount: 25.0,
        transaction_currency: "USD"
      )

      expect(txn.transaction_type).to eq("REFUND")
    end
  end

  describe ".simulate_notify_three_ds" do
    it "sends a 3DS delegation-mode notification" do
      stub_request(:post, "#{BASE_URL}/api/v1/simulation/issuing/threeds/notify")
        .with(body: hash_including(card_number: "4242424242424242"))
        .to_return(
          status: 200,
          body: { status: "SUCCESS" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      response = described_class.simulate_notify_three_ds(card_number: "4242424242424242")

      expect(response["status"]).to eq("SUCCESS")
    end
  end
end
