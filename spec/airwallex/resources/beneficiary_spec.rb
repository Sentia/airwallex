# frozen_string_literal: true

require "spec_helper"

RSpec.describe Airwallex::Beneficiary do
  let(:auth_response) do
    {
      status: 200,
      body: { token: "test_token" }.to_json,
      headers: { "Content-Type" => "application/json" }
    }
  end

  before do
    stub_request(:post, "https://api-demo.airwallex.com/api/v1/authentication/login")
      .to_return(auth_response)
  end

  describe ".resource_path" do
    it "returns correct path" do
      expect(described_class.resource_path).to eq("/api/v1/beneficiaries")
    end
  end

  describe ".create" do
    let(:create_params) do
      {
        bank_details: {
          account_number: "123456789",
          account_routing_type1: "aba",
          account_routing_value1: "026009593",
          bank_country_code: "US"
        },
        beneficiary_type: "BUSINESS",
        company_name: "Acme Corp",
        request_id: "req_123"
      }
    end

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
      stub_request(:post, "https://api-demo.airwallex.com/api/v1/beneficiaries/create")
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
      expect(beneficiary.company_name).to eq("Acme Corp")
      expect(beneficiary.beneficiary_type).to eq("BUSINESS")
    end

    it "sends POST request to correct endpoint" do
      described_class.create(create_params)

      expect(WebMock).to have_requested(:post, "https://api-demo.airwallex.com/api/v1/beneficiaries/create")
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
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/beneficiaries/ben_123")
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
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/beneficiaries")
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

  describe ".delete" do
    before do
      stub_request(:delete, "https://api-demo.airwallex.com/api/v1/beneficiaries/ben_123")
        .to_return(
          status: 200,
          body: {}.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "deletes beneficiary" do
      result = described_class.delete("ben_123")

      expect(result).to be true
    end

    it "sends DELETE request to correct endpoint" do
      described_class.delete("ben_123")

      expect(WebMock).to have_requested(:delete, "https://api-demo.airwallex.com/api/v1/beneficiaries/ben_123")
    end
  end
end
