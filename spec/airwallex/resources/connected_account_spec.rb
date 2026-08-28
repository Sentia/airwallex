# frozen_string_literal: true

require "spec_helper"

RSpec.describe Airwallex::ConnectedAccount do

  describe ".resource_path" do
    it "returns correct path" do
      expect(described_class.resource_path).to eq("/api/v1/accounts")
    end
  end

  describe ".create" do
    # account_details is a required top-level wrapper; nickname/
    # primary_contact/customer_agreements are top-level siblings.
    # legal_entity_type is "BUSINESS" or "INDIVIDUAL", not "COMPANY".
    let(:create_params) do
      {
        nickname: "Acme Advertiser",
        primary_contact: { email: "contact@acme.example" },
        account_details: {
          legal_entity_type: "BUSINESS",
          business_details: {
            business_name: "Acme Corp",
            business_structure: "COMPANY"
          }
        }
      }
    end

    before do
      stub_request(:post, "#{BASE_URL}/api/v1/accounts/create")
        .with(body: hash_including(create_params))
        .to_return(
          status: 200,
          body: { id: "acct_123", status: "PENDING" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "creates a connected account" do
      account = described_class.create(create_params)

      expect(account).to be_a(described_class)
      expect(account.id).to eq("acct_123")
      expect(account.status).to eq("PENDING")
    end
  end

  describe ".retrieve" do
    before do
      stub_request(:get, "#{BASE_URL}/api/v1/accounts/acct_123")
        .to_return(
          status: 200,
          body: { id: "acct_123", status: "ACTIVE" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "retrieves a connected account by id" do
      account = described_class.retrieve("acct_123")

      expect(account.id).to eq("acct_123")
    end
  end

  describe "#legal_entity_id" do
    it "reads legal_entity_id out of account_details" do
      account = described_class.new(
        id: "acct_123",
        account_details: { legal_entity_id: "le_test123" }
      )

      expect(account.legal_entity_id).to eq("le_test123")
    end

    it "returns nil when account_details is absent" do
      account = described_class.new(id: "acct_123")

      expect(account.legal_entity_id).to be_nil
    end
  end

  describe "#submit" do
    let(:account) { described_class.new(id: "acct_123", status: "PENDING") }

    before do
      stub_request(:post, "#{BASE_URL}/api/v1/accounts/acct_123/submit")
        .to_return(
          status: 200,
          body: { id: "acct_123", status: "UNDER_REVIEW" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "submits the account for KYC/KYB verification" do
      result = account.submit

      expect(result).to eq(account)
      expect(account.status).to eq("UNDER_REVIEW")
    end
  end

  describe ".list" do
    before do
      stub_request(:get, "#{BASE_URL}/api/v1/accounts")
        .to_return(
          status: 200,
          body: {
            items: [
              { id: "acct_1", status: "ACTIVE" },
              { id: "acct_2", status: "PENDING" }
            ],
            has_more: false
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "lists connected accounts" do
      accounts = described_class.list

      expect(accounts).to be_a(Airwallex::ListObject)
      expect(accounts.size).to eq(2)
    end
  end

  describe "#update" do
    let(:account) { described_class.new(id: "acct_123", nick_name: "old_name") }

    before do
      stub_request(:post, "#{BASE_URL}/api/v1/accounts/acct_123/update")
        .with(body: hash_including(nick_name: "new_name"))
        .to_return(
          status: 200,
          body: { id: "acct_123", nick_name: "new_name" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "updates the account" do
      result = account.update(nick_name: "new_name")

      expect(result).to eq(account)
      expect(account.nick_name).to eq("new_name")
    end
  end

  describe "#agree_to_terms_and_conditions" do
    let(:account) { described_class.new(id: "acct_123") }

    before do
      stub_request(:post, "#{BASE_URL}/api/v1/accounts/acct_123/terms_and_conditions/agree")
        .to_return(
          status: 200,
          body: { id: "acct_123", terms_agreed: true }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "agrees to the terms and conditions" do
      result = account.agree_to_terms_and_conditions

      expect(result).to eq(account)
      expect(account.terms_agreed).to be true
    end
  end

  describe "#suspend" do
    let(:account) { described_class.new(id: "acct_123", status: "ACTIVE") }

    before do
      stub_request(:post, "#{BASE_URL}/api/v1/accounts/acct_123/suspend")
        .to_return(
          status: 200,
          body: { id: "acct_123", status: "SUSPENDED" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "suspends the account" do
      result = account.suspend

      expect(result).to eq(account)
      expect(account.status).to eq("SUSPENDED")
    end
  end

  describe "#reactivate" do
    let(:account) { described_class.new(id: "acct_123", status: "SUSPENDED") }

    before do
      stub_request(:post, "#{BASE_URL}/api/v1/accounts/acct_123/reactivate")
        .to_return(
          status: 200,
          body: { id: "acct_123", status: "ACTIVE" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "reactivates the account" do
      result = account.reactivate

      expect(result).to eq(account)
      expect(account.status).to eq("ACTIVE")
    end
  end

  describe ".current" do
    before do
      stub_request(:get, "#{BASE_URL}/api/v1/account")
        .to_return(
          status: 200,
          body: { id: "acct_123", account_type: "PLATFORM" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "retrieves whichever account the request is authenticated as" do
      account = described_class.current

      expect(account).to be_a(described_class)
      expect(account.id).to eq("acct_123")
    end
  end

  describe ".wallet_info" do
    before do
      stub_request(:get, "#{BASE_URL}/api/v1/account/wallet_info")
        .to_return(
          status: 200,
          body: { balances: [{ currency: "AUD", available_amount: 1000.00 }] }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "retrieves wallet info for the current account" do
      result = described_class.wallet_info

      expect(result["balances"]).not_to be_empty
    end
  end
end
