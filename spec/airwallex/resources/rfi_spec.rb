# frozen_string_literal: true

require "spec_helper"

RSpec.describe Airwallex::RFI do
  describe ".simulate_create" do
    it "raises an RFI" do
      stub_request(:post, "#{BASE_URL}/api/v1/simulation/rfis/create")
        .with(body: hash_including(type: "KYC"))
        .to_return(
          status: 200,
          body: { id: "rfi_123", type: "KYC", status: "OPEN" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      rfi = described_class.simulate_create(type: "KYC", questions: [{ answer: { type: "TEXT" } }])

      expect(rfi).to be_a(described_class)
      expect(rfi.status).to eq("OPEN")
    end
  end

  describe ".simulate_close" do
    it "closes an RFI by id" do
      stub_request(:post, "#{BASE_URL}/api/v1/simulation/rfis/rfi_123/close")
        .to_return(
          status: 200,
          body: { id: "rfi_123", status: "CLOSED" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      rfi = described_class.simulate_close("rfi_123")

      expect(rfi.status).to eq("CLOSED")
    end
  end

  describe ".simulate_follow_up" do
    it "follows up on an RFI by id" do
      stub_request(:post, "#{BASE_URL}/api/v1/simulation/rfis/rfi_123/follow_up")
        .to_return(
          status: 200,
          body: { id: "rfi_123", status: "OPEN" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      rfi = described_class.simulate_follow_up("rfi_123", questions: [{ id: "q_1" }])

      expect(rfi.status).to eq("OPEN")
    end
  end

  describe "#simulate_close" do
    let(:rfi) { described_class.new(id: "rfi_123", status: "OPEN") }

    it "closes this RFI and refreshes its state" do
      stub_request(:post, "#{BASE_URL}/api/v1/simulation/rfis/rfi_123/close")
        .to_return(
          status: 200,
          body: { id: "rfi_123", status: "CLOSED" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = rfi.simulate_close

      expect(result).to eq(rfi)
      expect(rfi.status).to eq("CLOSED")
    end
  end

  describe "#simulate_follow_up" do
    let(:rfi) { described_class.new(id: "rfi_123", status: "CLOSED") }

    it "follows up on this RFI and refreshes its state" do
      stub_request(:post, "#{BASE_URL}/api/v1/simulation/rfis/rfi_123/follow_up")
        .to_return(
          status: 200,
          body: { id: "rfi_123", status: "OPEN" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      rfi.simulate_follow_up(questions: [{ answer: { type: "TEXT" } }])

      expect(rfi.status).to eq("OPEN")
    end
  end
end
