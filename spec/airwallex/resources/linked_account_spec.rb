# frozen_string_literal: true

require "spec_helper"

RSpec.describe Airwallex::LinkedAccount do
  describe ".simulate_accept_mandate" do
    it "transitions the mandate from PROCESSING to ACTIVE" do
      stub_request(:post, "#{BASE_URL}/api/v1/simulation/linked_accounts/la_123/mandate/accept")
        .to_return(status: 200, body: "")

      expect(described_class.simulate_accept_mandate("la_123")).to be(true)
    end
  end

  describe ".simulate_reject_mandate" do
    it "transitions the mandate from PROCESSING to INACTIVE" do
      stub_request(:post, "#{BASE_URL}/api/v1/simulation/linked_accounts/la_123/mandate/reject")
        .to_return(status: 200, body: "")

      expect(described_class.simulate_reject_mandate("la_123")).to be(true)
    end
  end

  describe ".simulate_cancel_mandate" do
    it "transitions the mandate to INACTIVE" do
      stub_request(:post, "#{BASE_URL}/api/v1/simulation/linked_accounts/la_123/mandate/cancel")
        .to_return(status: 200, body: "")

      expect(described_class.simulate_cancel_mandate("la_123")).to be(true)
    end
  end

  describe ".simulate_fail_microdeposits" do
    it "transitions the linked account from REQUIRES_ACTION to FAILED" do
      stub_request(:post, "#{BASE_URL}/api/v1/simulation/linked_accounts/la_123/fail_microdeposits")
        .to_return(status: 200, body: "")

      expect(described_class.simulate_fail_microdeposits("la_123")).to be(true)
    end
  end

  describe "error handling" do
    it "raises when the mandate isn't in a valid starting state" do
      stub_request(:post, "#{BASE_URL}/api/v1/simulation/linked_accounts/la_bad/mandate/accept")
        .to_return(
          status: 400,
          body: { code: "invalid_status_for_operation", message: "Mandate is not in PROCESSING status" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect do
        described_class.simulate_accept_mandate("la_bad")
      end.to raise_error(Airwallex::BadRequestError, /not in PROCESSING status/)
    end
  end
end
