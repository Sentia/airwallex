# frozen_string_literal: true

require "spec_helper"

RSpec.describe Airwallex::Cardholder do
  describe ".simulate_pass_review" do
    it "bypasses the cardholder's RFI review stage" do
      stub_request(:post, "#{BASE_URL}/api/v1/simulation/issuing/cardholders/chd_123/pass_review")
        .to_return(
          status: 200,
          body: { id: "chd_123", status: "READY" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      cardholder = described_class.simulate_pass_review("chd_123")

      expect(cardholder).to be_a(described_class)
      expect(cardholder.status).to eq("READY")
    end
  end
end
