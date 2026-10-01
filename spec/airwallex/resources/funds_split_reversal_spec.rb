require "spec_helper"

RSpec.describe Airwallex::FundsSplitReversal do
  describe ".resource_path" do
    it "returns correct path" do
      expect(described_class.resource_path).to eq("/api/v1/pa/funds_split_reversals")
    end
  end

  describe ".create" do
    let(:create_params) do
      {
        request_id: "req_123",
        funds_split_id: "spt_123",
        amount: "500.0",
        metadata: { payout_id: "42" }
      }
    end

    before do
      stub_request(:post, "#{BASE_URL}/api/v1/pa/funds_split_reversals/create")
        .with(body: hash_including(funds_split_id: "spt_123", amount: "500.0", request_id: "req_123"))
        .to_return(
          status: 201,
          body: {
            id: "rev_123", request_id: "req_123", funds_split_id: "spt_123",
            amount: "500.0", status: "CREATED", metadata: { payout_id: "42" }
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "creates a funds split reversal" do
      reversal = described_class.create(create_params)

      expect(reversal).to be_a(described_class)
      expect(reversal.id).to eq("rev_123")
      expect(reversal.status).to eq("CREATED")
      expect(reversal.metadata).to eq(payout_id: "42")
    end

    it "sends x-on-behalf-of when given" do
      described_class.create(create_params, headers: { "x-on-behalf-of" => "acct_123" })

      expect(WebMock).to have_requested(:post, "#{BASE_URL}/api/v1/pa/funds_split_reversals/create")
        .with(headers: { "x-on-behalf-of" => "acct_123" })
    end

    it "raises on duplicate_request" do
      stub_request(:post, "#{BASE_URL}/api/v1/pa/funds_split_reversals/create")
        .to_return(
          status: 400,
          body: { code: "duplicate_request", message: "Duplicate request" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect { described_class.create(create_params) }.to raise_error(Airwallex::BadRequestError)
    end
  end

  describe ".retrieve" do
    before do
      stub_request(:get, "#{BASE_URL}/api/v1/pa/funds_split_reversals/rev_123")
        .to_return(
          status: 200,
          body: { id: "rev_123", status: "SETTLED" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "retrieves a funds split reversal by id" do
      reversal = described_class.retrieve("rev_123")

      expect(reversal.id).to eq("rev_123")
      expect(reversal.status).to eq("SETTLED")
    end
  end

  describe ".list" do
    before do
      stub_request(:get, "#{BASE_URL}/api/v1/pa/funds_split_reversals")
        .with(query: { funds_split_id: "spt_123", page_num: 0, page_size: 10 })
        .to_return(
          status: 200,
          body: {
            items: [{ id: "rev_1", funds_split_id: "spt_123", status: "RELEASED" }],
            has_more: false
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "lists reversals for a funds split" do
      reversals = described_class.list(funds_split_id: "spt_123", page_num: 0, page_size: 10)

      expect(reversals).to be_a(Airwallex::ListObject)
      expect(reversals.first).to be_a(described_class)
      expect(reversals.first.id).to eq("rev_1")
    end
  end
end
