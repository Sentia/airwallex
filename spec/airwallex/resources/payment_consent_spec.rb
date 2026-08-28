# frozen_string_literal: true

require "spec_helper"

RSpec.describe Airwallex::PaymentConsent do

  describe ".resource_path" do
    it "returns correct path" do
      expect(described_class.resource_path).to eq("/api/v1/pa/payment_consents")
    end
  end

  describe ".create" do
    # next_triggered_by/merchant_trigger_reason are required for this consent
    # to later be usable to create a PaymentSource.
    let(:create_params) do
      {
        customer_id: "cus_123",
        next_triggered_by: "merchant",
        merchant_trigger_reason: "unscheduled"
      }
    end

    before do
      stub_request(:post, "#{BASE_URL}/api/v1/pa/payment_consents/create")
        .with(body: hash_including(create_params))
        .to_return(
          status: 200,
          body: { id: "consent_123", customer_id: "cus_123", status: "PENDING" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "creates a payment consent" do
      consent = described_class.create(create_params)

      expect(consent).to be_a(described_class)
      expect(consent.id).to eq("consent_123")
      expect(consent.status).to eq("PENDING")
    end
  end

  describe ".retrieve" do
    before do
      stub_request(:get, "#{BASE_URL}/api/v1/pa/payment_consents/consent_123")
        .to_return(
          status: 200,
          body: { id: "consent_123", status: "VERIFIED" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "retrieves a payment consent by id" do
      consent = described_class.retrieve("consent_123")

      expect(consent.id).to eq("consent_123")
      expect(consent.status).to eq("VERIFIED")
    end
  end

  describe ".list" do
    before do
      stub_request(:get, "#{BASE_URL}/api/v1/pa/payment_consents")
        .with(query: { customer_id: "cus_123" })
        .to_return(
          status: 200,
          body: {
            items: [
              { id: "consent_1", customer_id: "cus_123", status: "VERIFIED" },
              { id: "consent_2", customer_id: "cus_123", status: "DISABLED" }
            ],
            has_more: false
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "lists payment consents for a customer" do
      consents = described_class.list(customer_id: "cus_123")

      expect(consents).to be_a(Airwallex::ListObject)
      expect(consents.size).to eq(2)
    end
  end

  describe "#update" do
    let(:consent) { described_class.new(id: "consent_123", metadata: {}) }

    before do
      stub_request(:post, "#{BASE_URL}/api/v1/pa/payment_consents/consent_123/update")
        .with(body: hash_including(metadata: { order_id: "ord_1" }))
        .to_return(
          status: 200,
          body: { id: "consent_123", metadata: { order_id: "ord_1" } }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "updates the consent" do
      result = consent.update(metadata: { order_id: "ord_1" })

      expect(result).to eq(consent)
      expect(consent.metadata[:order_id]).to eq("ord_1")
    end
  end

  describe "#verify" do
    let(:consent) { described_class.new(id: "consent_123", status: "PENDING") }

    before do
      stub_request(:post, "#{BASE_URL}/api/v1/pa/payment_consents/consent_123/verify")
        .to_return(
          status: 200,
          body: { id: "consent_123", status: "VERIFIED" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "verifies the consent" do
      result = consent.verify

      expect(result).to eq(consent)
      expect(consent.status).to eq("VERIFIED")
    end
  end

  describe "#verify_continue" do
    let(:consent) { described_class.new(id: "consent_123", status: "REQUIRES_CUSTOMER_ACTION") }

    before do
      stub_request(:post, "#{BASE_URL}/api/v1/pa/payment_consents/consent_123/verify_continue")
        .to_return(
          status: 200,
          body: { id: "consent_123", status: "VERIFIED" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "continues verification" do
      result = consent.verify_continue

      expect(result).to eq(consent)
      expect(consent.status).to eq("VERIFIED")
    end
  end

  describe "#disable" do
    let(:consent) { described_class.new(id: "consent_123", status: "VERIFIED") }

    before do
      stub_request(:post, "#{BASE_URL}/api/v1/pa/payment_consents/consent_123/disable")
        .to_return(
          status: 200,
          body: { id: "consent_123", status: "DISABLED" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "disables the consent" do
      result = consent.disable

      expect(result).to eq(consent)
      expect(consent.status).to eq("DISABLED")
    end
  end
end
