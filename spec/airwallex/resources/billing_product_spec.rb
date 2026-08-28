# frozen_string_literal: true

require "spec_helper"

RSpec.describe Airwallex::BillingProduct do

  describe ".resource_path" do
    it "returns correct path" do
      expect(described_class.resource_path).to eq("/api/v1/billing/products")
    end
  end

  describe ".create" do
    before do
      stub_request(:post, "#{BASE_URL}/api/v1/billing/products/create")
        .with(body: hash_including(name: "Instalment Plan"))
        .to_return(
          status: 200,
          body: { id: "prod_123", name: "Instalment Plan" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "creates a billing product" do
      product = described_class.create(name: "Instalment Plan")

      expect(product).to be_a(described_class)
      expect(product.id).to eq("prod_123")
    end
  end

  describe ".retrieve" do
    before do
      stub_request(:get, "#{BASE_URL}/api/v1/billing/products/prod_123")
        .to_return(
          status: 200,
          body: { id: "prod_123", name: "Instalment Plan" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "retrieves a billing product by id" do
      product = described_class.retrieve("prod_123")

      expect(product.id).to eq("prod_123")
    end
  end

  describe ".list" do
    before do
      stub_request(:get, "#{BASE_URL}/api/v1/billing/products")
        .to_return(
          status: 200,
          body: {
            items: [
              { id: "prod_1", name: "Instalment Plan" },
              { id: "prod_2", name: "Annual Plan" }
            ],
            has_more: false
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "lists billing products" do
      products = described_class.list

      expect(products).to be_a(Airwallex::ListObject)
      expect(products.size).to eq(2)
      expect(products.first.id).to eq("prod_1")
    end
  end

  describe "#update" do
    let(:product) { described_class.new(id: "prod_123", name: "Instalment Plan") }

    before do
      stub_request(:post, "#{BASE_URL}/api/v1/billing/products/prod_123/update")
        .with(body: hash_including(name: "Instalment Plan (v2)"))
        .to_return(
          status: 200,
          body: { id: "prod_123", name: "Instalment Plan (v2)" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "updates the product" do
      result = product.update(name: "Instalment Plan (v2)")

      expect(result).to eq(product)
      expect(product.name).to eq("Instalment Plan (v2)")
    end
  end
end
