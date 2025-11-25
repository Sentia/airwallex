# frozen_string_literal: true

require "spec_helper"

RSpec.describe Airwallex::Transfer do
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
      expect(described_class.resource_path).to eq("/api/v1/transfers")
    end
  end

  describe ".create" do
    let(:create_params) do
      {
        beneficiary_id: "ben_123",
        amount: 1000.00,
        source_currency: "USD",
        transfer_method: "LOCAL",
        request_id: "req_123"
      }
    end

    let(:transfer_response) do
      {
        id: "tfr_123",
        beneficiary_id: "ben_123",
        amount: 1000.00,
        source_currency: "USD",
        transfer_method: "LOCAL",
        status: "pending"
      }
    end

    before do
      stub_request(:post, "https://api-demo.airwallex.com/api/v1/transfers/create")
        .with(body: hash_including(create_params))
        .to_return(
          status: 200,
          body: transfer_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "creates transfer" do
      transfer = described_class.create(create_params)

      expect(transfer).to be_a(described_class)
      expect(transfer.id).to eq("tfr_123")
      expect(transfer.amount).to eq(1000.00)
      expect(transfer.status).to eq("pending")
    end

    it "sends POST request to correct endpoint" do
      described_class.create(create_params)

      expect(WebMock).to have_requested(:post, "https://api-demo.airwallex.com/api/v1/transfers/create")
    end
  end

  describe ".retrieve" do
    let(:transfer_response) do
      {
        id: "tfr_123",
        beneficiary_id: "ben_123",
        amount: 1000.00,
        source_currency: "USD",
        status: "completed"
      }
    end

    before do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/transfers/tfr_123")
        .to_return(
          status: 200,
          body: transfer_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "retrieves transfer by id" do
      transfer = described_class.retrieve("tfr_123")

      expect(transfer).to be_a(described_class)
      expect(transfer.id).to eq("tfr_123")
      expect(transfer.status).to eq("completed")
    end
  end

  describe ".list" do
    let(:list_response) do
      {
        items: [
          { id: "tfr_1", amount: 100, source_currency: "USD" },
          { id: "tfr_2", amount: 200, source_currency: "EUR" }
        ],
        has_more: false
      }
    end

    before do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/transfers")
        .with(query: { page_size: 20 })
        .to_return(
          status: 200,
          body: list_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "lists transfers" do
      list = described_class.list(page_size: 20)

      expect(list).to be_a(Airwallex::ListObject)
      expect(list.size).to eq(2)
      expect(list.first.id).to eq("tfr_1")
      expect(list.last.id).to eq("tfr_2")
    end

    it "returns ListObject with resources" do
      list = described_class.list(page_size: 20)

      expect(list.data).to all(be_a(described_class))
    end
  end

  describe "#cancel" do
    let(:transfer) do
      described_class.new(
        id: "tfr_123",
        amount: 1000.00,
        source_currency: "USD",
        status: "pending"
      )
    end

    let(:cancelled_response) do
      {
        id: "tfr_123",
        amount: 1000.00,
        source_currency: "USD",
        status: "cancelled"
      }
    end

    before do
      stub_request(:post, "https://api-demo.airwallex.com/api/v1/transfers/tfr_123/cancel")
        .to_return(
          status: 200,
          body: cancelled_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "cancels transfer" do
      result = transfer.cancel

      expect(result).to eq(transfer)
      expect(transfer.status).to eq("cancelled")
    end

    it "sends POST request to cancel endpoint" do
      transfer.cancel

      expect(WebMock).to have_requested(:post, "https://api-demo.airwallex.com/api/v1/transfers/tfr_123/cancel")
    end
  end
end
