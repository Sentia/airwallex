require "spec_helper"

RSpec.describe Airwallex::ConnectedAccountTransfer do
  describe ".resource_path" do
    it "returns correct path" do
      expect(described_class.resource_path).to eq("/api/v1/connected_account_transfers")
    end
  end

  describe ".create" do
    let(:create_params) do
      {
        request_id: "req_123",
        amount: "100.00",
        currency: "AUD",
        destination: "acct_123",
        reason: "transfer_to_own_account",
        reference: "Ledger top-up"
      }
    end

    before do
      stub_request(:post, "#{BASE_URL}/api/v1/connected_account_transfers/create")
        .with(body: hash_including(create_params))
        .to_return(
          status: 201,
          body: { id: "cat_123", destination: "acct_123", amount: "100.00", currency: "AUD", status: "NEW" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "creates a connected account transfer" do
      transfer = described_class.create(create_params)

      expect(transfer).to be_a(described_class)
      expect(transfer.id).to eq("cat_123")
      expect(transfer.status).to eq("NEW")
    end

    it "sends x-on-behalf-of to debit a connected account" do
      described_class.create(create_params, headers: { "x-on-behalf-of" => "acct_456" })

      expect(WebMock).to have_requested(:post, "#{BASE_URL}/api/v1/connected_account_transfers/create")
        .with(headers: { "x-on-behalf-of" => "acct_456" })
    end

    it "raises on insufficient_fund" do
      stub_request(:post, "#{BASE_URL}/api/v1/connected_account_transfers/create")
        .to_return(
          status: 400,
          body: { code: "insufficient_fund", message: "Insufficient fund" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect { described_class.create(create_params) }.to raise_error(Airwallex::BadRequestError)
    end
  end

  describe ".retrieve" do
    before do
      stub_request(:get, "#{BASE_URL}/api/v1/connected_account_transfers/cat_123")
        .to_return(
          status: 200,
          body: { id: "cat_123", status: "SETTLED" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "retrieves a connected account transfer by id" do
      transfer = described_class.retrieve("cat_123")

      expect(transfer.id).to eq("cat_123")
      expect(transfer.status).to eq("SETTLED")
    end
  end

  describe ".list" do
    before do
      stub_request(:get, "#{BASE_URL}/api/v1/connected_account_transfers")
        .with(query: { destination: "acct_123", status: "SETTLED" })
        .to_return(
          status: 200,
          body: {
            items: [{ id: "cat_1", destination: "acct_123", status: "SETTLED" }],
            has_more: false
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "lists connected account transfers with filters" do
      transfers = described_class.list(destination: "acct_123", status: "SETTLED")

      expect(transfers).to be_a(Airwallex::ListObject)
      expect(transfers.size).to eq(1)
      expect(transfers.first.id).to eq("cat_1")
    end
  end
end
