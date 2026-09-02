# frozen_string_literal: true

require "spec_helper"

RSpec.describe Airwallex::Beneficiary do

  describe ".resource_path" do
    it "returns correct path" do
      expect(described_class.resource_path).to eq("/api/v1/beneficiaries")
    end
  end

  describe ".create" do
    # nickname/payer_entity_type/transfer_methods are top-level siblings of
    # `beneficiary`, not nested inside it. local_clearing_system is
    # country-specific (BANK_TRANSFER for AU, not e.g. ACH).
    let(:create_params) do
      {
        nickname: "Acme Corp",
        payer_entity_type: "COMPANY",
        transfer_methods: ["LOCAL"],
        beneficiary: {
          entity_type: "COMPANY",
          company_name: "Acme Corp",
          address: {
            country_code: "AU",
            city: "Melbourne",
            state: "VIC",
            postcode: "3000",
            street_address: "15 William Street"
          },
          bank_details: {
            account_name: "Acme Corp",
            account_number: "12750852",
            account_currency: "AUD",
            bank_country_code: "AU",
            bank_name: "National Australia Bank",
            account_routing_type1: "bsb",
            account_routing_value1: "083064",
            local_clearing_system: "BANK_TRANSFER"
          }
        }
      }
    end

    let(:beneficiary_response) do
      {
        id: "ben_123",
        nickname: "Acme Corp",
        beneficiary: {
          entity_type: "COMPANY",
          company_name: "Acme Corp",
          bank_details: {
            account_number: "12750852",
            bank_country_code: "AU"
          }
        }
      }
    end

    before do
      stub_request(:post, "#{BASE_URL}/api/v1/beneficiaries/create")
        .with(body: hash_including(create_params))
        .to_return(
          status: 200,
          body: beneficiary_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "creates beneficiary" do
      beneficiary = described_class.create(create_params)

      expect(beneficiary).to be_a(described_class)
      expect(beneficiary.id).to eq("ben_123")
      expect(beneficiary.nickname).to eq("Acme Corp")
      expect(beneficiary.beneficiary[:company_name]).to eq("Acme Corp")
    end

    it "sends POST request to correct endpoint" do
      described_class.create(create_params)

      expect(WebMock).to have_requested(:post, "#{BASE_URL}/api/v1/beneficiaries/create")
    end
  end

  describe ".retrieve" do
    let(:beneficiary_response) do
      {
        id: "ben_123",
        bank_details: {
          account_number: "123456789",
          bank_country_code: "US"
        },
        beneficiary_type: "BUSINESS",
        company_name: "Acme Corp"
      }
    end

    before do
      stub_request(:get, "#{BASE_URL}/api/v1/beneficiaries/ben_123")
        .to_return(
          status: 200,
          body: beneficiary_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "retrieves beneficiary by id" do
      beneficiary = described_class.retrieve("ben_123")

      expect(beneficiary).to be_a(described_class)
      expect(beneficiary.id).to eq("ben_123")
      expect(beneficiary.company_name).to eq("Acme Corp")
    end
  end

  describe ".list" do
    let(:list_response) do
      {
        items: [
          { id: "ben_1", company_name: "Company A", beneficiary_type: "BUSINESS" },
          { id: "ben_2", first_name: "John", last_name: "Doe", beneficiary_type: "INDIVIDUAL" }
        ],
        has_more: false
      }
    end

    before do
      stub_request(:get, "#{BASE_URL}/api/v1/beneficiaries")
        .with(query: { page_size: 20 })
        .to_return(
          status: 200,
          body: list_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "lists beneficiaries" do
      list = described_class.list(page_size: 20)

      expect(list).to be_a(Airwallex::ListObject)
      expect(list.size).to eq(2)
      expect(list.first.id).to eq("ben_1")
      expect(list.last.id).to eq("ben_2")
    end

    it "returns ListObject with resources" do
      list = described_class.list(page_size: 20)

      expect(list.data).to all(be_a(described_class))
    end
  end

  describe ".update" do
    # Same top-level `beneficiary` wrapper as .create/.validate. Doesn't
    # support a partial patch — needs the full payload resent.
    let(:update_params) do
      {
        transfer_methods: ["LOCAL"],
        beneficiary: {
          entity_type: "COMPANY",
          company_name: "Acme Corp Ltd",
          bank_details: { account_currency: "AUD", bank_country_code: "AU" }
        }
      }
    end

    before do
      stub_request(:post, "#{BASE_URL}/api/v1/beneficiaries/ben_123/update")
        .with(body: hash_including(update_params))
        .to_return(
          status: 200,
          body: { id: "ben_123", company_name: "Acme Corp Ltd" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "updates beneficiary by id" do
      beneficiary = described_class.update("ben_123", update_params)

      expect(beneficiary).to be_a(described_class)
      expect(beneficiary.company_name).to eq("Acme Corp Ltd")
    end
  end

  describe ".delete" do
    before do
      stub_request(:post, "#{BASE_URL}/api/v1/beneficiaries/ben_123/delete")
        .to_return(
          status: 200,
          body: "true",
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "deletes beneficiary" do
      result = described_class.delete("ben_123")

      expect(result).to be true
    end

    it "sends POST request to the delete endpoint" do
      described_class.delete("ben_123")

      expect(WebMock).to have_requested(:post, "#{BASE_URL}/api/v1/beneficiaries/ben_123/delete")
    end

    it "returns false when deletion did not take place" do
      stub_request(:post, "#{BASE_URL}/api/v1/beneficiaries/ben_456/delete")
        .to_return(
          status: 200,
          body: "false",
          headers: { "Content-Type" => "application/json" }
        )

      result = described_class.delete("ben_456")

      expect(result).to be false
    end
  end

  describe ".validate" do
    # Same top-level `beneficiary` wrapper as .create.
    let(:validate_params) do
      {
        beneficiary: {
          entity_type: "COMPANY",
          bank_details: { account_number: "123456789", bank_country_code: "AU" }
        }
      }
    end

    before do
      stub_request(:post, "#{BASE_URL}/api/v1/beneficiaries/validate")
        .with(body: hash_including(validate_params))
        .to_return(
          status: 200,
          body: { valid: true }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "validates beneficiary details before creation" do
      result = described_class.validate(validate_params)

      expect(result[:valid]).to be true
    end
  end

  describe ".verify_account" do
    let(:verify_params) do
      {
        bank_details: {
          account_number: "123456789",
          bank_country_code: "AU"
        },
        beneficiary_type: "BUSINESS"
      }
    end

    before do
      stub_request(:post, "#{BASE_URL}/api/v1/beneficiaries/verify_account")
        .with(body: hash_including(verify_params))
        .to_return(
          status: 200,
          body: {
            code: "VERIFIED",
            message: "stubbed",
            details: {
              account_name_match_result: "PARTIAL_MATCH",
              resolved_account_name: "J SMITH",
              resolved_bank_name: "Commonwealth Bank of Australia"
            }
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "verifies beneficiary bank account ownership via CoP" do
      result = described_class.verify_account(verify_params)

      expect(result[:code]).to eq("VERIFIED")
      expect(result[:details][:account_name_match_result]).to eq("PARTIAL_MATCH")
      expect(result[:details][:resolved_bank_name]).to eq("Commonwealth Bank of Australia")
    end

    it "sends POST request to the verify_account endpoint" do
      described_class.verify_account(verify_params)

      expect(WebMock).to have_requested(:post, "#{BASE_URL}/api/v1/beneficiaries/verify_account")
    end
  end

  describe ".api_schema" do
    before do
      stub_request(:post, "#{BASE_URL}/api/v1/beneficiary_api_schemas/generate")
        .with(body: hash_including(beneficiary_type: "BUSINESS", bank_country_code: "AU"))
        .to_return(
          status: 200,
          body: { fields: [{ name: "account_number", required: true }] }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "retrieves the API validation schema" do
      schema = described_class.api_schema(beneficiary_type: "BUSINESS", bank_country_code: "AU")

      expect(schema[:fields]).not_to be_empty
      expect(schema[:fields].first[:name]).to eq("account_number")
    end
  end

  describe ".form_schema" do
    before do
      stub_request(:post, "#{BASE_URL}/api/v1/beneficiary_form_schemas/generate")
        .with(body: hash_including(beneficiary_type: "BUSINESS", bank_country_code: "AU"))
        .to_return(
          status: 200,
          body: {
            key: "newRecipient",
            condition: {},
            fields: [
              {
                path: "beneficiary.bank_details.account_number",
                required: true,
                enabled: true,
                field: {
                  type: "TEXT",
                  label: "Account number",
                  example: "12345678",
                  rule: { pattern: "^[0-9]{6,9}$" }
                }
              }
            ]
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "retrieves the dynamic form schema, symbolized down through the nested fields array" do
      schema = described_class.form_schema(beneficiary_type: "BUSINESS", bank_country_code: "AU")

      expect(schema[:key]).to eq("newRecipient")
      expect(schema[:fields]).not_to be_empty

      field = schema[:fields].first
      expect(field[:path]).to eq("beneficiary.bank_details.account_number")
      expect(field[:field][:rule][:pattern]).to eq("^[0-9]{6,9}$")
    end
  end

  describe ".supported_financial_institutions" do
    # account_currency, entity_type, transfer_method, and keyword (a
    # bank-name search term, min 3 chars) are all required.
    let(:query_params) do
      {
        bank_country_code: "AU",
        account_currency: "AUD",
        entity_type: "COMPANY",
        transfer_method: "LOCAL",
        keyword: "Commonwealth"
      }
    end

    before do
      stub_request(:get, "#{BASE_URL}/api/v1/beneficiary_form_schemas/supported_financial_institutions")
        .with(query: query_params)
        .to_return(
          status: 200,
          body: { items: [{ name: "Commonwealth Bank", swift_code: "CTBAAU2S" }] }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "lists supported financial institutions" do
      result = described_class.supported_financial_institutions(query_params)

      expect(result[:items]).not_to be_empty
      expect(result[:items].first[:name]).to eq("Commonwealth Bank")
    end
  end
end
