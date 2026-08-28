# frozen_string_literal: true

require "spec_helper"

RSpec.describe Airwallex::BillingPrice do

  describe ".resource_path" do
    it "returns correct path" do
      expect(described_class.resource_path).to eq("/api/v1/billing/prices")
    end
  end

  describe ".create" do
    # Flat payload. pricing_model is required; recurring is what makes a
    # price subscribable.
    let(:create_params) do
      {
        product_id: "prod_123",
        currency: "AUD",
        pricing_model: "PER_UNIT",
        unit_amount: 250.00,
        recurring: { period: 1, period_unit: "MONTH" }
      }
    end

    before do
      stub_request(:post, "#{BASE_URL}/api/v1/billing/prices/create")
        .with(body: hash_including(create_params))
        .to_return(
          status: 200,
          body: { id: "price_123" }.merge(create_params).to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "creates a billing price" do
      price = described_class.create(create_params)

      expect(price).to be_a(described_class)
      expect(price.id).to eq("price_123")
      expect(price.unit_amount).to eq(250.00)
    end
  end

  describe ".retrieve" do
    before do
      stub_request(:get, "#{BASE_URL}/api/v1/billing/prices/price_123")
        .to_return(
          status: 200,
          body: { id: "price_123", currency: "AUD" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "retrieves a billing price by id" do
      price = described_class.retrieve("price_123")

      expect(price.id).to eq("price_123")
    end
  end

  describe ".list" do
    before do
      stub_request(:get, "#{BASE_URL}/api/v1/billing/prices")
        .to_return(
          status: 200,
          body: {
            items: [
              { id: "price_1", currency: "AUD" },
              { id: "price_2", currency: "USD" }
            ],
            has_more: false
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "lists billing prices" do
      prices = described_class.list

      expect(prices).to be_a(Airwallex::ListObject)
      expect(prices.size).to eq(2)
    end
  end

  describe "#update" do
    let(:price) { described_class.new(id: "price_123", unit_amount: 250.00) }

    before do
      stub_request(:post, "#{BASE_URL}/api/v1/billing/prices/price_123/update")
        .with(body: hash_including(unit_amount: 300.00))
        .to_return(
          status: 200,
          body: { id: "price_123", unit_amount: 300.00 }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "updates the price" do
      result = price.update(unit_amount: 300.00)

      expect(result).to eq(price)
      expect(price.unit_amount).to eq(300.00)
    end
  end
end
