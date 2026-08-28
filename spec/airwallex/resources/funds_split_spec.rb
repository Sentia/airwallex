# frozen_string_literal: true

require "spec_helper"

RSpec.describe Airwallex::FundsSplit do

  describe ".resource_path" do
    it "returns correct path" do
      expect(described_class.resource_path).to eq("/api/v1/pa/funds_splits")
    end
  end

  describe ".create" do
    let(:create_params) do
      {
        payment_intent_id: "int_123",
        splits: [{ account_id: "acct_123", amount: 50.00 }]
      }
    end

    before do
      stub_request(:post, "#{BASE_URL}/api/v1/pa/funds_splits/create")
        .with(body: hash_including(payment_intent_id: "int_123"))
        .to_return(
          status: 200,
          body: { id: "split_123", payment_intent_id: "int_123", status: "PENDING" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "creates a funds split" do
      split = described_class.create(create_params)

      expect(split).to be_a(described_class)
      expect(split.id).to eq("split_123")
      expect(split.status).to eq("PENDING")
    end
  end

  describe ".retrieve" do
    before do
      stub_request(:get, "#{BASE_URL}/api/v1/pa/funds_splits/split_123")
        .to_return(
          status: 200,
          body: { id: "split_123", status: "PENDING" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "retrieves a funds split by id" do
      split = described_class.retrieve("split_123")

      expect(split.id).to eq("split_123")
    end
  end

  describe ".list" do
    before do
      stub_request(:get, "#{BASE_URL}/api/v1/pa/funds_splits")
        .with(query: { payment_intent_id: "int_123" })
        .to_return(
          status: 200,
          body: {
            items: [
              { id: "split_1", payment_intent_id: "int_123", status: "RELEASED" }
            ],
            has_more: false
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "lists funds splits" do
      splits = described_class.list(payment_intent_id: "int_123")

      expect(splits).to be_a(Airwallex::ListObject)
      expect(splits.size).to eq(1)
    end
  end

  describe "#release" do
    let(:split) { described_class.new(id: "split_123", status: "PENDING") }

    before do
      stub_request(:post, "#{BASE_URL}/api/v1/pa/funds_splits/split_123/release")
        .to_return(
          status: 200,
          body: { id: "split_123", status: "RELEASED" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "releases the split" do
      result = split.release

      expect(result).to eq(split)
      expect(split.status).to eq("RELEASED")
    end
  end
end
