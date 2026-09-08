# frozen_string_literal: true

require "spec_helper"

RSpec.describe Airwallex::AccountAmendment do

  describe ".resource_path" do
    it "returns correct path" do
      expect(described_class.resource_path).to eq("/api/v1/account/amendments")
    end
  end

  describe ".create" do
    # `target` identifies the dotted path being amended; the changed section
    # is a top-level sibling keyed by its own name, not wrapped in a generic
    # "changes" key.
    let(:create_params) do
      {
        target: "account_details.store_details",
        store_details: { store_name: "New Store Name" }
      }
    end

    before do
      stub_request(:post, "#{BASE_URL}/api/v1/account/amendments/create")
        .with(body: hash_including(create_params))
        .to_return(
          status: 200,
          body: { id: "amend_123", status: "PENDING" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "creates an account amendment" do
      amendment = described_class.create(create_params)

      expect(amendment).to be_a(described_class)
      expect(amendment.id).to eq("amend_123")
      expect(amendment.status).to eq("PENDING")
    end
  end

  describe ".retrieve" do
    before do
      stub_request(:get, "#{BASE_URL}/api/v1/account/amendments/amend_123")
        .to_return(
          status: 200,
          body: { id: "amend_123", status: "APPROVED" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "retrieves an amendment by id" do
      amendment = described_class.retrieve("amend_123")

      expect(amendment.id).to eq("amend_123")
      expect(amendment.status).to eq("APPROVED")
    end
  end

  describe ".simulate_approve" do
    it "approves a pending amendment by id" do
      stub_request(:post, "#{BASE_URL}/api/v1/simulation/account/amendments/amend_123/approve")
        .to_return(
          status: 200,
          body: { id: "amend_123", status: "APPROVED" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      amendment = described_class.simulate_approve("amend_123")

      expect(amendment.status).to eq("APPROVED")
    end
  end

  describe ".simulate_reject" do
    it "rejects a pending amendment by id" do
      stub_request(:post, "#{BASE_URL}/api/v1/simulation/account/amendments/amend_123/reject")
        .to_return(
          status: 200,
          body: { id: "amend_123", status: "REJECTED" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      amendment = described_class.simulate_reject("amend_123")

      expect(amendment.status).to eq("REJECTED")
    end
  end

  describe "#simulate_approve" do
    let(:amendment) { described_class.new(id: "amend_123", status: "PENDING") }

    it "approves this amendment and refreshes its state" do
      stub_request(:post, "#{BASE_URL}/api/v1/simulation/account/amendments/amend_123/approve")
        .to_return(
          status: 200,
          body: { id: "amend_123", status: "APPROVED" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = amendment.simulate_approve

      expect(result).to eq(amendment)
      expect(amendment.status).to eq("APPROVED")
    end
  end

  describe "#simulate_reject" do
    let(:amendment) { described_class.new(id: "amend_123", status: "PENDING") }

    it "rejects this amendment and refreshes its state" do
      stub_request(:post, "#{BASE_URL}/api/v1/simulation/account/amendments/amend_123/reject")
        .to_return(
          status: 200,
          body: { id: "amend_123", status: "REJECTED" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      amendment.simulate_reject

      expect(amendment.status).to eq("REJECTED")
    end
  end
end
