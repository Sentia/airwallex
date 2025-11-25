# frozen_string_literal: true

require "spec_helper"

RSpec.describe Airwallex::BatchTransfer do
  let(:client) { Airwallex.client }

  before do
    stub_request(:post, "https://api-demo.airwallex.com/api/v1/authentication/login")
      .to_return(
        status: 200,
        body: { token: "test_token", expires_at: (Time.now + 3600).iso8601 }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  describe ".create" do
    it "creates a batch transfer with multiple transfers" do
      stub_request(:post, "https://api-demo.airwallex.com/api/v1/batch_transfers/create")
        .to_return(
          status: 200,
          body: {
            id: "batch_abc123",
            status: "PROCESSING",
            source_currency: "USD",
            total_count: 2,
            success_count: 0,
            failed_count: 0,
            transfers: [
              {
                id: "trf_001",
                beneficiary_id: "ben_001",
                amount: 100.00,
                status: "PENDING"
              },
              {
                id: "trf_002",
                beneficiary_id: "ben_002",
                amount: 200.00,
                status: "PENDING"
              }
            ],
            created_at: "2025-11-25T10:00:00Z"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      batch = described_class.create(
        request_id: "batch_test_123",
        source_currency: "USD",
        transfers: [
          { beneficiary_id: "ben_001", amount: 100.00, reason: "Payout 1" },
          { beneficiary_id: "ben_002", amount: 200.00, reason: "Payout 2" }
        ]
      )

      expect(batch).to be_a(Airwallex::BatchTransfer)
      expect(batch.id).to eq("batch_abc123")
      expect(batch.status).to eq("PROCESSING")
      expect(batch.total_count).to eq(2)
      expect(batch.transfers).to be_an(Array)
      expect(batch.transfers.size).to eq(2)
    end

    it "creates a batch transfer with single transfer" do
      stub_request(:post, "https://api-demo.airwallex.com/api/v1/batch_transfers/create")
        .to_return(
          status: 200,
          body: {
            id: "batch_single",
            status: "COMPLETED",
            source_currency: "AUD",
            total_count: 1,
            success_count: 1,
            failed_count: 0,
            transfers: [
              { id: "trf_solo", amount: 500.00, status: "COMPLETED" }
            ]
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      batch = described_class.create(
        source_currency: "AUD",
        transfers: [
          { beneficiary_id: "ben_999", amount: 500.00 }
        ]
      )

      expect(batch.total_count).to eq(1)
      expect(batch.success_count).to eq(1)
      expect(batch.status).to eq("COMPLETED")
    end

    it "handles idempotency with request_id" do
      request_id = "idempotent_batch_#{Time.now.to_i}"

      stub_request(:post, "https://api-demo.airwallex.com/api/v1/batch_transfers/create")
        .with(body: hash_including(request_id: request_id))
        .to_return(
          status: 200,
          body: {
            id: "batch_idem",
            status: "PROCESSING",
            request_id: request_id,
            transfers: []
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      batch1 = described_class.create(
        request_id: request_id,
        source_currency: "USD",
        transfers: [{ beneficiary_id: "ben_001", amount: 100.00 }]
      )

      batch2 = described_class.create(
        request_id: request_id,
        source_currency: "USD",
        transfers: [{ beneficiary_id: "ben_001", amount: 100.00 }]
      )

      expect(batch1.id).to eq(batch2.id)
    end
  end

  describe ".retrieve" do
    it "retrieves a batch transfer by ID" do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/batch_transfers/batch_retrieve_123")
        .to_return(
          status: 200,
          body: {
            id: "batch_retrieve_123",
            status: "COMPLETED",
            source_currency: "USD",
            total_count: 3,
            success_count: 2,
            failed_count: 1,
            transfers: [
              { id: "trf_001", status: "COMPLETED" },
              { id: "trf_002", status: "COMPLETED" },
              { id: "trf_003", status: "FAILED", failure_reason: "Invalid account" }
            ],
            created_at: "2025-11-25T09:00:00Z"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      batch = described_class.retrieve("batch_retrieve_123")

      expect(batch).to be_a(Airwallex::BatchTransfer)
      expect(batch.id).to eq("batch_retrieve_123")
      expect(batch.status).to eq("COMPLETED")
      expect(batch.success_count).to eq(2)
      expect(batch.failed_count).to eq(1)
      expect(batch.transfers.size).to eq(3)
    end

    it "shows individual transfer statuses" do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/batch_transfers/batch_mixed")
        .to_return(
          status: 200,
          body: {
            id: "batch_mixed",
            status: "PARTIALLY_FAILED",
            transfers: [
              { id: "trf_success", status: "COMPLETED", amount: 100.00 },
              { id: "trf_fail", status: "FAILED", failure_reason: "Insufficient funds" }
            ]
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      batch = described_class.retrieve("batch_mixed")
      successful = batch.transfers.select { |t| t["status"] == "COMPLETED" }
      failed = batch.transfers.select { |t| t["status"] == "FAILED" }

      expect(successful.size).to eq(1)
      expect(failed.size).to eq(1)
    end
  end

  describe ".list" do
    it "lists batch transfers with pagination" do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/batch_transfers")
        .with(query: hash_including(page_size: "10"))
        .to_return(
          status: 200,
          body: {
            items: [
              { id: "batch_001", status: "COMPLETED", total_count: 5 },
              { id: "batch_002", status: "PROCESSING", total_count: 10 }
            ],
            has_more: true,
            page_num: 0
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      batches = described_class.list(page_size: 10)

      expect(batches).to be_a(Airwallex::ListObject)
      expect(batches.size).to eq(2)
      expect(batches.has_more).to be true
      expect(batches.first.id).to eq("batch_001")
    end

    it "filters batch transfers by status" do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/batch_transfers")
        .with(query: hash_including(status: "COMPLETED"))
        .to_return(
          status: 200,
          body: {
            items: [
              { id: "batch_completed_1", status: "COMPLETED" },
              { id: "batch_completed_2", status: "COMPLETED" }
            ],
            has_more: false
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      batches = described_class.list(status: "COMPLETED")

      expect(batches.size).to eq(2)
      expect(batches.all? { |b| b.status == "COMPLETED" }).to be true
    end

    it "filters by date range" do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/batch_transfers")
        .with(query: hash_including(
          from_created_at: "2025-11-01T00:00:00Z",
          to_created_at: "2025-11-30T23:59:59Z"
        ))
        .to_return(
          status: 200,
          body: {
            items: [
              { id: "batch_nov_1", created_at: "2025-11-15T10:00:00Z" }
            ],
            has_more: false
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      batches = described_class.list(
        from_created_at: "2025-11-01T00:00:00Z",
        to_created_at: "2025-11-30T23:59:59Z"
      )

      expect(batches.size).to eq(1)
    end

    it "supports auto-paging" do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/batch_transfers?page_size=2")
        .to_return(
          status: 200,
          body: {
            items: [
              { id: "batch_page1_1" },
              { id: "batch_page1_2" }
            ],
            has_more: true
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      stub_request(:get, "https://api-demo.airwallex.com/api/v1/batch_transfers?offset=2&page_size=2")
        .to_return(
          status: 200,
          body: {
            items: [
              { id: "batch_page2_1" }
            ],
            has_more: false
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      all_ids = []
      described_class.list(page_size: 2).auto_paging_each do |batch|
        all_ids << batch.id
      end

      expect(all_ids).to eq(["batch_page1_1", "batch_page1_2", "batch_page2_1"])
    end
  end

  describe "error handling" do
    it "handles validation errors" do
      stub_request(:post, "https://api-demo.airwallex.com/api/v1/batch_transfers/create")
        .to_return(
          status: 400,
          body: {
            code: "invalid_argument",
            message: "transfers must contain at least one item"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect do
        described_class.create(
          source_currency: "USD",
          transfers: []
        )
      end.to raise_error(Airwallex::BadRequestError, /transfers must contain at least one item/)
    end

    it "handles insufficient funds error" do
      stub_request(:post, "https://api-demo.airwallex.com/api/v1/batch_transfers/create")
        .to_return(
          status: 400,
          body: {
            code: "insufficient_fund",
            message: "Insufficient balance in USD account"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect do
        described_class.create(
          source_currency: "USD",
          transfers: [{ beneficiary_id: "ben_001", amount: 999999.00 }]
        )
      end.to raise_error(Airwallex::BadRequestError, /Insufficient balance/)
    end
  end
end
