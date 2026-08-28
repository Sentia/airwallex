# frozen_string_literal: true

require "spec_helper"

RSpec.describe Airwallex::GlobalAccountMandate do
  describe ".resource_path" do
    it "returns the nested path scoped to the parent global account" do
      expect(described_class.resource_path("gacc_123")).to eq("/api/v1/global_accounts/gacc_123/mandates")
    end
  end

  describe "#cancel" do
    let(:mandate) { described_class.new(id: "mandate_123", global_account_id: "gacc_123", status: "ACTIVE") }

    before do
      stub_request(:post, "#{BASE_URL}/api/v1/global_accounts/gacc_123/mandates/mandate_123/cancel")
        .to_return(
          status: 200,
          body: { id: "mandate_123", global_account_id: "gacc_123", status: "CANCELLED" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "cancels the mandate" do
      result = mandate.cancel

      expect(result).to eq(mandate)
      expect(mandate.status).to eq("CANCELLED")
    end
  end
end
