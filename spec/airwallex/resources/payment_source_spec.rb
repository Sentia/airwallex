# frozen_string_literal: true

require "spec_helper"

RSpec.describe Airwallex::PaymentSource do

  describe ".resource_path" do
    it "returns correct path" do
      expect(described_class.resource_path).to eq("/api/v1/billing/payment_sources")
    end
  end

  describe ".create" do
    # external_id is a PaymentMethod's id, not a PaymentConsent's.
    let(:create_params) do
      {
        billing_customer_id: "bcus_123",
        external_id: "mtd_123",
        linked_payment_account_id: "acct_123"
      }
    end

    before do
      stub_request(:post, "#{BASE_URL}/api/v1/billing/payment_sources/create")
        .with(body: hash_including(create_params))
        .to_return(
          status: 200,
          body: { id: "psrc_123", billing_customer_id: "bcus_123" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "creates a payment source" do
      source = described_class.create(create_params)

      expect(source).to be_a(described_class)
      expect(source.id).to eq("psrc_123")
    end
  end

  describe ".retrieve" do
    before do
      stub_request(:get, "#{BASE_URL}/api/v1/billing/payment_sources/psrc_123")
        .to_return(
          status: 200,
          body: { id: "psrc_123", billing_customer_id: "bcus_123" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "retrieves a payment source by id" do
      source = described_class.retrieve("psrc_123")

      expect(source.id).to eq("psrc_123")
    end
  end

  describe ".list" do
    before do
      stub_request(:get, "#{BASE_URL}/api/v1/billing/payment_sources")
        .to_return(
          status: 200,
          body: {
            items: [
              { id: "psrc_1", billing_customer_id: "bcus_123" }
            ],
            has_more: false
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "lists payment sources" do
      sources = described_class.list

      expect(sources).to be_a(Airwallex::ListObject)
      expect(sources.size).to eq(1)
    end
  end
end
