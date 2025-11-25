# frozen_string_literal: true

require "spec_helper"

RSpec.describe Airwallex::PaymentIntent do
  let(:auth_response) do
    {
      status: 200,
      body: { token: "test_token" }.to_json,
      headers: { "Content-Type" => "application/json" }
    }
  end

  before do
    stub_request(:post, "https://api-demo.airwallex.com/api/v1/authentication/login")
      .to_return(auth_response)
  end

  describe ".resource_path" do
    it "returns correct path" do
      expect(described_class.resource_path).to eq("/api/v1/pa/payment_intents")
    end
  end

  describe ".create" do
    let(:create_params) do
      {
        amount: 100.00,
        currency: "USD",
        merchant_order_id: "order_123",
        request_id: "req_123"
      }
    end

    let(:intent_response) do
      {
        id: "pi_123",
        amount: 100.00,
        currency: "USD",
        status: "requires_payment_method",
        merchant_order_id: "order_123"
      }
    end

    before do
      stub_request(:post, "https://api-demo.airwallex.com/api/v1/pa/payment_intents/create")
        .with(body: hash_including(create_params))
        .to_return(
          status: 200,
          body: intent_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "creates payment intent" do
      intent = described_class.create(create_params)

      expect(intent).to be_a(described_class)
      expect(intent.id).to eq("pi_123")
      expect(intent.amount).to eq(100.00)
      expect(intent.currency).to eq("USD")
      expect(intent.status).to eq("requires_payment_method")
    end

    it "sends POST request to correct endpoint" do
      described_class.create(create_params)

      expect(WebMock).to have_requested(:post, "https://api-demo.airwallex.com/api/v1/pa/payment_intents/create")
        .with(body: hash_including(create_params))
    end
  end

  describe ".retrieve" do
    let(:intent_response) do
      {
        id: "pi_123",
        amount: 100.00,
        currency: "USD",
        status: "succeeded"
      }
    end

    before do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/pa/payment_intents/pi_123")
        .to_return(
          status: 200,
          body: intent_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "retrieves payment intent by id" do
      intent = described_class.retrieve("pi_123")

      expect(intent).to be_a(described_class)
      expect(intent.id).to eq("pi_123")
      expect(intent.status).to eq("succeeded")
    end
  end

  describe ".list" do
    let(:list_response) do
      {
        items: [
          { id: "pi_1", amount: 100, currency: "USD" },
          { id: "pi_2", amount: 200, currency: "EUR" }
        ],
        has_more: false
      }
    end

    before do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/pa/payment_intents")
        .with(query: { page_size: 10 })
        .to_return(
          status: 200,
          body: list_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "lists payment intents" do
      list = described_class.list(page_size: 10)

      expect(list).to be_a(Airwallex::ListObject)
      expect(list.size).to eq(2)
      expect(list.first.id).to eq("pi_1")
      expect(list.last.id).to eq("pi_2")
    end

    it "returns ListObject with resources" do
      list = described_class.list(page_size: 10)

      expect(list.data).to all(be_a(described_class))
    end
  end

  describe ".update" do
    let(:update_params) do
      {
        amount: 200.00,
        request_id: "req_update_123"
      }
    end

    let(:updated_response) do
      {
        id: "pi_123",
        amount: 200.00,
        currency: "USD",
        status: "requires_payment_method"
      }
    end

    before do
      stub_request(:put, "https://api-demo.airwallex.com/api/v1/pa/payment_intents/pi_123")
        .with(body: hash_including(update_params))
        .to_return(
          status: 200,
          body: updated_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "updates payment intent" do
      intent = described_class.update("pi_123", update_params)

      expect(intent).to be_a(described_class)
      expect(intent.id).to eq("pi_123")
      expect(intent.amount).to eq(200.00)
    end
  end

  describe "#confirm" do
    let(:intent) do
      described_class.new(
        id: "pi_123",
        amount: 100.00,
        currency: "USD",
        status: "requires_payment_method"
      )
    end

    let(:confirm_params) do
      {
        payment_method: {
          type: "card",
          card: { number: "4242424242424242" }
        }
      }
    end

    let(:confirmed_response) do
      {
        id: "pi_123",
        amount: 100.00,
        currency: "USD",
        status: "succeeded"
      }
    end

    before do
      stub_request(:post, "https://api-demo.airwallex.com/api/v1/pa/payment_intents/pi_123/confirm")
        .with(body: hash_including(confirm_params))
        .to_return(
          status: 200,
          body: confirmed_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "confirms payment intent" do
      result = intent.confirm(confirm_params)

      expect(result).to eq(intent)
      expect(intent.status).to eq("succeeded")
    end

    it "sends POST request to confirm endpoint" do
      intent.confirm(confirm_params)

      expect(WebMock).to have_requested(:post, "https://api-demo.airwallex.com/api/v1/pa/payment_intents/pi_123/confirm")
    end
  end

  describe "#cancel" do
    let(:intent) do
      described_class.new(
        id: "pi_123",
        amount: 100.00,
        currency: "USD",
        status: "requires_payment_method"
      )
    end

    let(:cancel_params) do
      {
        cancellation_reason: "requested_by_customer"
      }
    end

    let(:cancelled_response) do
      {
        id: "pi_123",
        amount: 100.00,
        currency: "USD",
        status: "cancelled"
      }
    end

    before do
      stub_request(:post, "https://api-demo.airwallex.com/api/v1/pa/payment_intents/pi_123/cancel")
        .with(body: hash_including(cancel_params))
        .to_return(
          status: 200,
          body: cancelled_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "cancels payment intent" do
      result = intent.cancel(cancel_params)

      expect(result).to eq(intent)
      expect(intent.status).to eq("cancelled")
    end
  end

  describe "#capture" do
    let(:intent) do
      described_class.new(
        id: "pi_123",
        amount: 100.00,
        currency: "USD",
        status: "requires_capture"
      )
    end

    let(:capture_params) do
      {
        amount: 100.00,
        request_id: "req_capture_123"
      }
    end

    let(:captured_response) do
      {
        id: "pi_123",
        amount: 100.00,
        currency: "USD",
        status: "succeeded",
        captured_amount: 100.00
      }
    end

    before do
      stub_request(:post, "https://api-demo.airwallex.com/api/v1/pa/payment_intents/pi_123/capture")
        .with(body: hash_including(capture_params))
        .to_return(
          status: 200,
          body: captured_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "captures authorized payment" do
      result = intent.capture(capture_params)

      expect(result).to eq(intent)
      expect(intent.status).to eq("succeeded")
      expect(intent.captured_amount).to eq(100.00)
    end
  end

  describe "#update" do
    let(:intent) do
      described_class.new(
        id: "pi_123",
        amount: 100.00,
        currency: "USD"
      )
    end

    let(:update_params) do
      {
        amount: 200.00
      }
    end

    let(:updated_response) do
      {
        id: "pi_123",
        amount: 200.00,
        currency: "USD"
      }
    end

    before do
      stub_request(:put, "https://api-demo.airwallex.com/api/v1/pa/payment_intents/pi_123")
        .with(body: hash_including(update_params))
        .to_return(
          status: 200,
          body: updated_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "updates instance" do
      result = intent.update(update_params)

      expect(result).to eq(intent)
      expect(intent.amount).to eq(200.00)
    end
  end

  describe "#save" do
    let(:intent) do
      described_class.new(
        id: "pi_123",
        amount: 100.00,
        currency: "USD"
      )
    end

    let(:updated_response) do
      {
        id: "pi_123",
        amount: 200.00,
        currency: "USD"
      }
    end

    before do
      stub_request(:put, "https://api-demo.airwallex.com/api/v1/pa/payment_intents/pi_123")
        .to_return(
          status: 200,
          body: updated_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "saves changed attributes" do
      intent.amount = 200.00
      intent.save

      expect(intent.amount).to eq(200.00)
    end

    it "does nothing if not dirty" do
      intent.save

      expect(WebMock).not_to have_requested(:put, /payment_intents/)
    end
  end
end
