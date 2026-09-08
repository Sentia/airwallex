# frozen_string_literal: true

require "spec_helper"

RSpec.describe Airwallex::Deposit do
  describe ".resource_path" do
    it "returns the real (non-simulation) deposits path" do
      expect(described_class.resource_path).to eq("/api/v1/deposits")
    end
  end

  describe ".create" do
    it "creates a Direct Debit deposit by pulling from a LinkedAccount" do
      stub_request(:post, "#{BASE_URL}/api/v1/deposits/create")
        .with(body: hash_including(funding_source_id: "la_123", amount: 50.0, currency: "AUD"))
        .to_return(
          status: 201,
          body: { id: "dep_dd_123", status: "PENDING", funding_source_id: "la_123" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      deposit = described_class.create(funding_source_id: "la_123", amount: 50.0, currency: "AUD")

      expect(deposit).to be_a(described_class)
      expect(deposit.status).to eq("PENDING")
    end
  end

  describe ".retrieve" do
    it "retrieves a deposit by id" do
      stub_request(:get, "#{BASE_URL}/api/v1/deposits/dep_123")
        .to_return(
          status: 200,
          body: { id: "dep_123", status: "SETTLED", type: "BANK_TRANSFER" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      deposit = described_class.retrieve("dep_123")

      expect(deposit.type).to eq("BANK_TRANSFER")
    end
  end

  describe ".list" do
    it "lists deposits" do
      stub_request(:get, "#{BASE_URL}/api/v1/deposits")
        .with(query: hash_including(page_size: "10"))
        .to_return(
          status: 200,
          body: { items: [{ id: "dep_1" }, { id: "dep_2" }], has_more: false }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      list = described_class.list(page_size: 10)

      expect(list).to be_a(Airwallex::ListObject)
      expect(list.size).to eq(2)
    end
  end

  describe ".simulate_create" do
    it "simulates a deposit landing in a global account" do
      stub_request(:post, "#{BASE_URL}/api/v1/simulation/deposit/create")
        .with(body: hash_including(amount: 100.0, global_account_id: "gacc_123"))
        .to_return(
          status: 200,
          body: { id: "dep_123", status: "SETTLED", amount: 100.0 }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      deposit = described_class.simulate_create(amount: 100.0, global_account_id: "gacc_123")

      expect(deposit).to be_a(described_class)
      expect(deposit.id).to eq("dep_123")
      expect(deposit.status).to eq("SETTLED")
    end
  end

  describe ".simulate_settle" do
    it "settles a pending deposit by id" do
      stub_request(:post, "#{BASE_URL}/api/v1/simulation/deposits/dep_123/settle")
        .to_return(
          status: 200,
          body: { id: "dep_123", status: "SETTLED" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      deposit = described_class.simulate_settle("dep_123")

      expect(deposit.status).to eq("SETTLED")
    end
  end

  describe ".simulate_reject" do
    it "rejects a pending deposit by id" do
      stub_request(:post, "#{BASE_URL}/api/v1/simulation/deposits/dep_123/reject")
        .to_return(
          status: 200,
          body: { id: "dep_123", status: "REJECTED" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      deposit = described_class.simulate_reject("dep_123")

      expect(deposit.status).to eq("REJECTED")
    end
  end

  describe ".simulate_reverse" do
    it "reverses a settled deposit by id" do
      stub_request(:post, "#{BASE_URL}/api/v1/simulation/deposits/dep_123/reverse")
        .to_return(
          status: 200,
          body: { id: "dep_456", status: "SETTLED", reversal_of: "dep_123" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      deposit = described_class.simulate_reverse("dep_123")

      expect(deposit.reversal_of).to eq("dep_123")
    end
  end

  describe "#simulate_settle" do
    let(:deposit) { described_class.new(id: "dep_123", status: "PENDING") }

    it "settles this deposit and refreshes its state" do
      stub_request(:post, "#{BASE_URL}/api/v1/simulation/deposits/dep_123/settle")
        .to_return(
          status: 200,
          body: { id: "dep_123", status: "SETTLED" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = deposit.simulate_settle

      expect(result).to eq(deposit)
      expect(deposit.status).to eq("SETTLED")
    end
  end

  describe "#simulate_reject" do
    let(:deposit) { described_class.new(id: "dep_123", status: "PENDING") }

    it "rejects this deposit and refreshes its state" do
      stub_request(:post, "#{BASE_URL}/api/v1/simulation/deposits/dep_123/reject")
        .to_return(
          status: 200,
          body: { id: "dep_123", status: "REJECTED" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      deposit.simulate_reject

      expect(deposit.status).to eq("REJECTED")
    end
  end

  describe "#simulate_reverse" do
    let(:deposit) { described_class.new(id: "dep_123", status: "SETTLED") }

    it "reverses this deposit and refreshes its state" do
      stub_request(:post, "#{BASE_URL}/api/v1/simulation/deposits/dep_123/reverse")
        .to_return(
          status: 200,
          body: { id: "dep_123", status: "REVERSED" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      deposit.simulate_reverse

      expect(deposit.status).to eq("REVERSED")
    end
  end
end
