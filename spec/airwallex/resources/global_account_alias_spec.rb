# frozen_string_literal: true

require "spec_helper"

RSpec.describe Airwallex::GlobalAccountAlias do
  describe ".resource_path" do
    it "returns the nested path scoped to the parent global account" do
      expect(described_class.resource_path("gacc_123")).to eq("/api/v1/global_accounts/gacc_123/aliases")
    end
  end

  describe "#initiate_port" do
    let(:alias_record) { described_class.new(id: "alias_123", global_account_id: "gacc_123", status: "CREATED") }

    before do
      stub_request(:post, "#{BASE_URL}/api/v1/global_accounts/gacc_123/aliases/alias_123/initiate_port")
        .to_return(
          status: 200,
          body: { id: "alias_123", global_account_id: "gacc_123", status: "PORTING" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "initiates the port and updates status" do
      result = alias_record.initiate_port

      expect(result).to eq(alias_record)
      expect(alias_record.status).to eq("PORTING")
    end
  end

  describe "#submit_verification_code" do
    let(:alias_record) do
      described_class.new(id: "alias_123", global_account_id: "gacc_123", status: "PENDING_VERIFICATION")
    end

    before do
      stub_request(:post, "#{BASE_URL}/api/v1/global_accounts/gacc_123/aliases/alias_123/submit_verification_code")
        .with(body: hash_including(code: "123456"))
        .to_return(
          status: 200,
          body: { id: "alias_123", global_account_id: "gacc_123", status: "ACTIVE" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "submits the verification code" do
      result = alias_record.submit_verification_code(code: "123456")

      expect(result).to eq(alias_record)
      expect(alias_record.status).to eq("ACTIVE")
    end
  end

  describe "#request_new_verification_code" do
    let(:alias_record) do
      described_class.new(id: "alias_123", global_account_id: "gacc_123", status: "PENDING_VERIFICATION")
    end

    before do
      path = "#{BASE_URL}/api/v1/global_accounts/gacc_123/aliases/alias_123/request_new_verification_code"
      stub_request(:post, path)
        .to_return(
          status: 200,
          body: { id: "alias_123", global_account_id: "gacc_123", status: "PENDING_VERIFICATION" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "requests a new verification code" do
      result = alias_record.request_new_verification_code

      expect(result).to eq(alias_record)
    end
  end

  describe "#cancel" do
    let(:alias_record) { described_class.new(id: "alias_123", global_account_id: "gacc_123", status: "ACTIVE") }

    before do
      stub_request(:post, "#{BASE_URL}/api/v1/global_accounts/gacc_123/aliases/alias_123/cancel")
        .to_return(
          status: 200,
          body: { id: "alias_123", global_account_id: "gacc_123", status: "CANCELLED" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "cancels the alias" do
      result = alias_record.cancel

      expect(result).to eq(alias_record)
      expect(alias_record.status).to eq("CANCELLED")
    end
  end
end
