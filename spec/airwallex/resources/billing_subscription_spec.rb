# frozen_string_literal: true

require "spec_helper"

RSpec.describe Airwallex::BillingSubscription do

  describe ".resource_path" do
    it "returns correct path" do
      expect(described_class.resource_path).to eq("/api/v1/billing/subscriptions")
    end
  end

  describe ".create" do
    # Confirmed against Airwallex's real API reference: flat payload; prices
    # attach via an `items:` array of { price_id:, quantity: }, not a flat
    # price_id; the date field is `starts_at`, not `start_date`.
    let(:create_params) do
      {
        billing_customer_id: "bcus_123",
        currency: "AUD",
        collection_method: "AUTO_CHARGE",
        legal_entity_id: "le_test123",
        starts_at: "2026-09-01T00:00:00+1000",
        items: [{ price_id: "price_123", quantity: 1 }]
      }
    end

    let(:subscription_response) do
      {
        id: "sub_123",
        billing_customer_id: "bcus_123",
        status: "PENDING",
        starts_at: "2026-09-01T00:00:00+1000"
      }
    end

    before do
      stub_request(:post, "#{BASE_URL}/api/v1/billing/subscriptions/create")
        .with(body: hash_including(create_params))
        .to_return(
          status: 200,
          body: subscription_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "creates a subscription with a deferred start date" do
      subscription = described_class.create(create_params)

      expect(subscription).to be_a(described_class)
      expect(subscription.id).to eq("sub_123")
      expect(subscription.status).to eq("PENDING")
      expect(subscription.starts_at).to eq("2026-09-01T00:00:00+1000")
    end
  end

  describe ".retrieve" do
    before do
      stub_request(:get, "#{BASE_URL}/api/v1/billing/subscriptions/sub_123")
        .to_return(
          status: 200,
          body: { id: "sub_123", status: "ACTIVE" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "retrieves a subscription by id" do
      subscription = described_class.retrieve("sub_123")

      expect(subscription.id).to eq("sub_123")
      expect(subscription.status).to eq("ACTIVE")
    end
  end

  describe "#update" do
    let(:subscription) { described_class.new(id: "sub_123", status: "ACTIVE") }

    before do
      stub_request(:post, "#{BASE_URL}/api/v1/billing/subscriptions/sub_123/update")
        .with(body: hash_including(price_id: "price_456"))
        .to_return(
          status: 200,
          body: { id: "sub_123", price_id: "price_456" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "updates the subscription" do
      result = subscription.update(price_id: "price_456")

      expect(result).to eq(subscription)
      expect(subscription.price_id).to eq("price_456")
    end
  end

  describe "#cancel" do
    let(:subscription) { described_class.new(id: "sub_123", status: "ACTIVE") }

    before do
      stub_request(:post, "#{BASE_URL}/api/v1/billing/subscriptions/sub_123/cancel")
        .to_return(
          status: 200,
          body: { id: "sub_123", status: "CANCELLED" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "cancels the subscription" do
      result = subscription.cancel

      expect(result).to eq(subscription)
      expect(subscription.status).to eq("CANCELLED")
    end
  end

  describe "#items" do
    let(:subscription) { described_class.new(id: "sub_123") }

    before do
      stub_request(:get, "#{BASE_URL}/api/v1/billing/subscriptions/sub_123/items")
        .to_return(
          status: 200,
          body: {
            items: [
              { id: "subitem_1", price_id: "price_123", quantity: 1 },
              { id: "subitem_2", price_id: "price_456", quantity: 2 }
            ],
            has_more: false
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "lists the subscription's line items" do
      items = subscription.items

      expect(items).to be_a(Airwallex::ListObject)
      expect(items.size).to eq(2)
      expect(items.first).to be_a(Airwallex::BillingSubscriptionItem)
      expect(items.first.id).to eq("subitem_1")
    end
  end

  describe "#item" do
    let(:subscription) { described_class.new(id: "sub_123") }

    before do
      stub_request(:get, "#{BASE_URL}/api/v1/billing/subscriptions/sub_123/items/subitem_1")
        .to_return(
          status: 200,
          body: { id: "subitem_1", price_id: "price_123", quantity: 1 }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "retrieves a single subscription line item" do
      item = subscription.item("subitem_1")

      expect(item).to be_a(Airwallex::BillingSubscriptionItem)
      expect(item.id).to eq("subitem_1")
      expect(item.quantity).to eq(1)
    end
  end
end
