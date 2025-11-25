# frozen_string_literal: true

require "spec_helper"

RSpec.describe Airwallex::Dispute do
  let(:client) { Airwallex.client }

  before do
    stub_request(:post, "https://api-demo.airwallex.com/api/v1/authentication/login")
      .to_return(
        status: 200,
        body: { token: "test_token", expires_at: (Time.now + 3600).iso8601 }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  describe ".retrieve" do
    it "retrieves a dispute by ID" do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/disputes/dis_123")
        .to_return(
          status: 200,
          body: {
            id: "dis_123",
            payment_intent_id: "int_abc123",
            amount: 100.00,
            currency: "USD",
            reason: "fraudulent",
            status: "OPEN",
            evidence_due_by: "2025-12-01T23:59:59Z",
            created_at: "2025-11-20T10:00:00Z"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      dispute = described_class.retrieve("dis_123")

      expect(dispute).to be_a(Airwallex::Dispute)
      expect(dispute.id).to eq("dis_123")
      expect(dispute.payment_intent_id).to eq("int_abc123")
      expect(dispute.amount).to eq(100.00)
      expect(dispute.reason).to eq("fraudulent")
      expect(dispute.status).to eq("OPEN")
    end

    it "retrieves dispute with evidence deadline" do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/disputes/dis_urgent")
        .to_return(
          status: 200,
          body: {
            id: "dis_urgent",
            status: "OPEN",
            evidence_due_by: "2025-11-26T23:59:59Z",
            created_at: "2025-11-25T10:00:00Z"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      dispute = described_class.retrieve("dis_urgent")

      expect(dispute.evidence_due_by).to eq("2025-11-26T23:59:59Z")
      expect(dispute.status).to eq("OPEN")
    end
  end

  describe ".list" do
    it "lists all disputes" do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/disputes")
        .with(query: hash_including(page_size: "20"))
        .to_return(
          status: 200,
          body: {
            items: [
              { id: "dis_001", status: "OPEN", amount: 50.00 },
              { id: "dis_002", status: "WON", amount: 100.00 }
            ],
            has_more: false,
            page_num: 0
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      disputes = described_class.list(page_size: 20)

      expect(disputes).to be_a(Airwallex::ListObject)
      expect(disputes.size).to eq(2)
      expect(disputes.first.id).to eq("dis_001")
    end

    it "filters disputes by status" do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/disputes")
        .with(query: hash_including(status: "OPEN"))
        .to_return(
          status: 200,
          body: {
            items: [
              { id: "dis_open_1", status: "OPEN" },
              { id: "dis_open_2", status: "OPEN" }
            ],
            has_more: false
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      disputes = described_class.list(status: "OPEN")

      expect(disputes.size).to eq(2)
      expect(disputes.all? { |d| d.status == "OPEN" }).to be true
    end

    it "filters disputes by payment_intent_id" do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/disputes")
        .with(query: hash_including(payment_intent_id: "int_abc123"))
        .to_return(
          status: 200,
          body: {
            items: [
              { id: "dis_for_payment", payment_intent_id: "int_abc123", status: "UNDER_REVIEW" }
            ],
            has_more: false
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      disputes = described_class.list(payment_intent_id: "int_abc123")

      expect(disputes.size).to eq(1)
      expect(disputes.first.payment_intent_id).to eq("int_abc123")
    end

    it "filters by reason" do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/disputes")
        .with(query: hash_including(reason: "product_not_received"))
        .to_return(
          status: 200,
          body: {
            items: [
              { id: "dis_product", reason: "product_not_received" }
            ],
            has_more: false
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      disputes = described_class.list(reason: "product_not_received")

      expect(disputes.first.reason).to eq("product_not_received")
    end

    it "supports auto-paging" do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/disputes?page_size=2")
        .to_return(
          status: 200,
          body: {
            items: [
              { id: "dis_page1_1" },
              { id: "dis_page1_2" }
            ],
            has_more: true
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      stub_request(:get, "https://api-demo.airwallex.com/api/v1/disputes?offset=2&page_size=2")
        .to_return(
          status: 200,
          body: {
            items: [
              { id: "dis_page2_1" }
            ],
            has_more: false
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      all_ids = []
      described_class.list(page_size: 2).auto_paging_each do |dispute|
        all_ids << dispute.id
      end

      expect(all_ids).to eq(["dis_page1_1", "dis_page1_2", "dis_page2_1"])
    end
  end

  describe "#accept" do
    it "accepts a dispute without challenging" do
      dispute_id = "dis_accept_123"

      # First retrieve
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/disputes/#{dispute_id}")
        .to_return(
          status: 200,
          body: {
            id: dispute_id,
            status: "OPEN",
            amount: 100.00
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      # Then accept
      stub_request(:post, "https://api-demo.airwallex.com/api/v1/disputes/#{dispute_id}/accept")
        .to_return(
          status: 200,
          body: {
            id: dispute_id,
            status: "ACCEPTED",
            amount: 100.00
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      dispute = described_class.retrieve(dispute_id)
      result = dispute.accept

      expect(result).to be_a(Airwallex::Dispute)
      expect(result.status).to eq("ACCEPTED")
      expect(dispute.status).to eq("ACCEPTED") # Object is updated
    end
  end

  describe "#submit_evidence" do
    it "submits evidence to challenge a dispute" do
      dispute_id = "dis_challenge_123"

      # First retrieve
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/disputes/#{dispute_id}")
        .to_return(
          status: 200,
          body: {
            id: dispute_id,
            status: "OPEN",
            amount: 200.00
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      # Then submit evidence
      stub_request(:post, "https://api-demo.airwallex.com/api/v1/disputes/#{dispute_id}/evidence")
        .with(
          body: hash_including(
            customer_communication: "Email thread",
            shipping_tracking_number: "1Z999AA10123456784"
          )
        )
        .to_return(
          status: 200,
          body: {
            id: dispute_id,
            status: "UNDER_REVIEW",
            amount: 200.00,
            evidence: {
              customer_communication: "Email thread",
              shipping_tracking_number: "1Z999AA10123456784"
            }
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      dispute = described_class.retrieve(dispute_id)
      result = dispute.submit_evidence(
        customer_communication: "Email thread",
        shipping_tracking_number: "1Z999AA10123456784"
      )

      expect(result).to be_a(Airwallex::Dispute)
      expect(result.status).to eq("UNDER_REVIEW")
      expect(dispute.status).to eq("UNDER_REVIEW")
    end

    it "submits comprehensive evidence" do
      dispute_id = "dis_full_evidence"

      stub_request(:get, "https://api-demo.airwallex.com/api/v1/disputes/#{dispute_id}")
        .to_return(
          status: 200,
          body: { id: dispute_id, status: "OPEN" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      stub_request(:post, "https://api-demo.airwallex.com/api/v1/disputes/#{dispute_id}/evidence")
        .with(
          body: hash_including(
            customer_communication: "Full email exchange",
            shipping_documentation: "Proof of delivery",
            customer_signature: "Signed receipt",
            receipt: "Invoice #12345",
            refund_policy: "30-day return policy",
            additional_information: "Customer had 60-day grace period"
          )
        )
        .to_return(
          status: 200,
          body: {
            id: dispute_id,
            status: "UNDER_REVIEW"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      dispute = described_class.retrieve(dispute_id)
      result = dispute.submit_evidence(
        customer_communication: "Full email exchange",
        shipping_documentation: "Proof of delivery",
        customer_signature: "Signed receipt",
        receipt: "Invoice #12345",
        refund_policy: "30-day return policy",
        additional_information: "Customer had 60-day grace period"
      )

      expect(result.status).to eq("UNDER_REVIEW")
    end

    it "handles evidence submission errors" do
      dispute_id = "dis_error"

      stub_request(:get, "https://api-demo.airwallex.com/api/v1/disputes/#{dispute_id}")
        .to_return(
          status: 200,
          body: { id: dispute_id, status: "OPEN" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      stub_request(:post, "https://api-demo.airwallex.com/api/v1/disputes/#{dispute_id}/evidence")
        .to_return(
          status: 400,
          body: {
            code: "evidence_past_due",
            message: "Evidence submission deadline has passed"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      dispute = described_class.retrieve(dispute_id)

      expect do
        dispute.submit_evidence(
          customer_communication: "Too late"
        )
      end.to raise_error(Airwallex::BadRequestError, /Evidence submission deadline has passed/)
    end
  end

  describe "error handling" do
    it "handles dispute not found" do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/disputes/dis_missing")
        .to_return(
          status: 404,
          body: {
            code: "resource_not_found",
            message: "Dispute not found"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect do
        described_class.retrieve("dis_missing")
      end.to raise_error(Airwallex::NotFoundError, /Dispute not found/)
    end

    it "handles invalid status filter" do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/disputes")
        .with(query: hash_including(status: "INVALID_STATUS"))
        .to_return(
          status: 400,
          body: {
            code: "invalid_argument",
            message: "status must be one of: OPEN, UNDER_REVIEW, WON, LOST, ACCEPTED"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect do
        described_class.list(status: "INVALID_STATUS")
      end.to raise_error(Airwallex::BadRequestError, /status must be one of/)
    end

    it "handles permission errors for accept" do
      dispute_id = "dis_forbidden"

      stub_request(:get, "https://api-demo.airwallex.com/api/v1/disputes/#{dispute_id}")
        .to_return(
          status: 200,
          body: { id: dispute_id, status: "WON" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      stub_request(:post, "https://api-demo.airwallex.com/api/v1/disputes/#{dispute_id}/accept")
        .to_return(
          status: 403,
          body: {
            code: "invalid_state",
            message: "Cannot accept a dispute that has already been won"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      dispute = described_class.retrieve(dispute_id)

      expect do
        dispute.accept
      end.to raise_error(Airwallex::PermissionError, /Cannot accept a dispute/)
    end
  end
end
