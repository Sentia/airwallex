# frozen_string_literal: true

require "spec_helper"

RSpec.describe Airwallex::Charge do

  describe ".resource_path" do
    it "returns correct path" do
      expect(described_class.resource_path).to eq("/api/v1/charges")
    end
  end

  describe ".create" do
    let(:create_params) do
      {
        account_id: "acct_123",
        amount: 100.00,
        currency: "AUD"
      }
    end

    before do
      stub_request(:post, "#{BASE_URL}/api/v1/charges/create")
        .with(body: hash_including(create_params))
        .to_return(
          status: 200,
          body: { id: "chg_123", account_id: "acct_123", status: "PENDING" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "creates a charge" do
      charge = described_class.create(create_params)

      expect(charge).to be_a(described_class)
      expect(charge.id).to eq("chg_123")
      expect(charge.status).to eq("PENDING")
    end
  end

  describe ".retrieve" do
    before do
      stub_request(:get, "#{BASE_URL}/api/v1/charges/chg_123")
        .to_return(
          status: 200,
          body: { id: "chg_123", status: "SETTLED" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "retrieves a charge by id" do
      charge = described_class.retrieve("chg_123")

      expect(charge.id).to eq("chg_123")
      expect(charge.status).to eq("SETTLED")
    end
  end

  describe ".list" do
    before do
      stub_request(:get, "#{BASE_URL}/api/v1/charges")
        .with(query: { account_id: "acct_123" })
        .to_return(
          status: 200,
          body: {
            items: [
              { id: "chg_1", account_id: "acct_123", status: "SETTLED" },
              { id: "chg_2", account_id: "acct_123", status: "PENDING" }
            ],
            has_more: false
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "lists charges" do
      charges = described_class.list(account_id: "acct_123")

      expect(charges).to be_a(Airwallex::ListObject)
      expect(charges.size).to eq(2)
    end
  end
end
