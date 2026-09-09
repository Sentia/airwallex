# frozen_string_literal: true

require "spec_helper"

RSpec.describe Airwallex::AccountOffboarding do
  describe ".resource_path" do
    it "returns the nested path scoped to the parent connected account" do
      expect(described_class.resource_path("acct_123")).to eq("/api/v1/simulation/accounts/acct_123/offboardings")
    end
  end

  describe ".simulate_complete" do
    it "completes an offboarding" do
      stub_request(:post, "#{BASE_URL}/api/v1/simulation/accounts/acct_123/offboardings/obd_456/complete")
        .to_return(
          status: 200,
          body: { id: "obd_456", status: "COMPLETED" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      offboarding = described_class.simulate_complete("acct_123", "obd_456")

      expect(offboarding.status).to eq("COMPLETED")
    end
  end

  describe ".simulate_cancel" do
    it "cancels an offboarding" do
      stub_request(:post, "#{BASE_URL}/api/v1/simulation/accounts/acct_123/offboardings/obd_456/cancel")
        .to_return(
          status: 200,
          body: { id: "obd_456", status: "CANCELLED" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      offboarding = described_class.simulate_cancel("acct_123", "obd_456")

      expect(offboarding.status).to eq("CANCELLED")
    end
  end
end
