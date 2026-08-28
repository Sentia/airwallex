# frozen_string_literal: true

require "spec_helper"

RSpec.describe Airwallex::GlobalAccount do

  describe ".resource_path" do
    it "returns correct path" do
      expect(described_class.resource_path).to eq("/api/v1/global_accounts")
    end
  end

  describe ".create" do
    let(:create_params) do
      {
        country_code: "AU",
        nick_name: "booking_12345",
        required_features: [{ transfer_method: "LOCAL" }]
      }
    end

    let(:account_response) do
      {
        id: "gacc_123",
        country_code: "AU",
        nick_name: "booking_12345",
        account_number: "12345678",
        status: "ACTIVE"
      }
    end

    before do
      stub_request(:post, "#{BASE_URL}/api/v1/global_accounts/create")
        .with(body: hash_including(country_code: "AU", nick_name: "booking_12345"))
        .to_return(
          status: 200,
          body: account_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "provisions a global account" do
      account = described_class.create(create_params)

      expect(account).to be_a(described_class)
      expect(account.id).to eq("gacc_123")
      expect(account.account_number).to eq("12345678")
    end
  end

  describe ".retrieve" do
    before do
      stub_request(:get, "#{BASE_URL}/api/v1/global_accounts/gacc_123")
        .to_return(
          status: 200,
          body: { id: "gacc_123", status: "ACTIVE" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "retrieves a global account by id" do
      account = described_class.retrieve("gacc_123")

      expect(account.id).to eq("gacc_123")
      expect(account.status).to eq("ACTIVE")
    end
  end

  describe "#transactions" do
    let(:account) { described_class.new(id: "gacc_123") }

    before do
      stub_request(:get, "#{BASE_URL}/api/v1/global_accounts/gacc_123/transactions")
        .to_return(
          status: 200,
          body: {
            items: [
              { id: "txn_1", amount: 100.00, currency: "AUD", remitter: "Jane Smith" },
              { id: "txn_2", amount: 50.00, currency: "AUD", remitter: "John Doe" }
            ],
            has_more: false
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "lists inbound transactions for reconciliation" do
      transactions = account.transactions

      expect(transactions).to be_a(Airwallex::ListObject)
      expect(transactions.size).to eq(2)
      expect(transactions.first.remitter).to eq("Jane Smith")
      expect(transactions.first).to be_a(Airwallex::GlobalAccountTransaction)
    end

    it "sends GET request to the transactions endpoint" do
      account.transactions

      expect(WebMock).to have_requested(:get, "#{BASE_URL}/api/v1/global_accounts/gacc_123/transactions")
    end
  end

  describe "#update" do
    let(:account) { described_class.new(id: "gacc_123", nick_name: "old_name") }

    before do
      stub_request(:post, "#{BASE_URL}/api/v1/global_accounts/gacc_123/update")
        .with(body: hash_including(nick_name: "new_name"))
        .to_return(
          status: 200,
          body: { id: "gacc_123", nick_name: "new_name" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "updates the account" do
      result = account.update(nick_name: "new_name")

      expect(result).to eq(account)
      expect(account.nick_name).to eq("new_name")
    end
  end

  describe "#close" do
    let(:account) { described_class.new(id: "gacc_123", status: "ACTIVE") }

    before do
      stub_request(:post, "#{BASE_URL}/api/v1/global_accounts/gacc_123/close")
        .to_return(
          status: 200,
          body: { id: "gacc_123", status: "CLOSED" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "closes the account" do
      result = account.close

      expect(result).to eq(account)
      expect(account.status).to eq("CLOSED")
    end
  end

  describe "#generate_statement_letter" do
    let(:account) { described_class.new(id: "gacc_123") }

    # account_statement_type and registration_info are required
    # (e.g. "AMAZON", for marketplace seller bank-ownership verification).
    let(:letter_params) do
      {
        account_statement_type: "AMAZON",
        registration_info: {
          agreement: true,
          registered_name: "Acme Corp",
          registered_email: "john@example.com",
          registered_address: {
            address: "15 William Street",
            city: "Melbourne",
            state: "VIC",
            postcode: "3000",
            country: "Australia"
          }
        }
      }
    end

    before do
      stub_request(:post, "#{BASE_URL}/api/v1/global_accounts/gacc_123/generate_statement_letter")
        .with(body: hash_including(letter_params))
        .to_return(
          status: 200,
          body: { document_url: "https://files.airwallex.com/statement_letter.pdf" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "returns the generated statement letter" do
      result = account.generate_statement_letter(letter_params)

      expect(result["document_url"]).to eq("https://files.airwallex.com/statement_letter.pdf")
    end
  end

  describe "#create_alias" do
    let(:account) { described_class.new(id: "gacc_123") }
    let(:alias_params) { { type: "PAYID_PHONE", value: "+61400000000" } }

    before do
      stub_request(:post, "#{BASE_URL}/api/v1/global_accounts/gacc_123/aliases/create")
        .with(body: hash_including(alias_params))
        .to_return(
          status: 200,
          body: { id: "alias_123", global_account_id: "gacc_123", status: "PENDING_VERIFICATION" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "creates an alias" do
      result = account.create_alias(alias_params)

      expect(result).to be_a(Airwallex::GlobalAccountAlias)
      expect(result.id).to eq("alias_123")
      expect(result.status).to eq("PENDING_VERIFICATION")
    end
  end

  describe "#alias" do
    let(:account) { described_class.new(id: "gacc_123") }

    before do
      stub_request(:get, "#{BASE_URL}/api/v1/global_accounts/gacc_123/aliases/alias_123")
        .to_return(
          status: 200,
          body: { id: "alias_123", global_account_id: "gacc_123" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "retrieves a single alias" do
      result = account.alias("alias_123")

      expect(result).to be_a(Airwallex::GlobalAccountAlias)
      expect(result.id).to eq("alias_123")
    end
  end

  describe "#aliases" do
    let(:account) { described_class.new(id: "gacc_123") }

    before do
      stub_request(:get, "#{BASE_URL}/api/v1/global_accounts/gacc_123/aliases")
        .to_return(
          status: 200,
          body: {
            items: [
              { id: "alias_1", global_account_id: "gacc_123", type: "PAYID_PHONE" },
              { id: "alias_2", global_account_id: "gacc_123", type: "PAYID_EMAIL" }
            ],
            has_more: false
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "lists aliases" do
      result = account.aliases

      expect(result).to be_a(Airwallex::ListObject)
      expect(result.size).to eq(2)
      expect(result.first).to be_a(Airwallex::GlobalAccountAlias)
    end
  end

  describe "#mandate" do
    let(:account) { described_class.new(id: "gacc_123") }

    before do
      stub_request(:get, "#{BASE_URL}/api/v1/global_accounts/gacc_123/mandates/mandate_123")
        .to_return(
          status: 200,
          body: { id: "mandate_123", global_account_id: "gacc_123", status: "ACTIVE" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "retrieves a single mandate" do
      result = account.mandate("mandate_123")

      expect(result).to be_a(Airwallex::GlobalAccountMandate)
      expect(result.id).to eq("mandate_123")
    end
  end

  describe "#mandates" do
    let(:account) { described_class.new(id: "gacc_123") }

    before do
      stub_request(:get, "#{BASE_URL}/api/v1/global_accounts/gacc_123/mandates")
        .to_return(
          status: 200,
          body: {
            items: [
              { id: "mandate_1", global_account_id: "gacc_123", status: "ACTIVE" }
            ],
            has_more: false
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "lists mandates" do
      result = account.mandates

      expect(result).to be_a(Airwallex::ListObject)
      expect(result.size).to eq(1)
      expect(result.first).to be_a(Airwallex::GlobalAccountMandate)
    end
  end
end
