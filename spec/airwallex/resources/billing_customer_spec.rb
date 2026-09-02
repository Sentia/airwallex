# frozen_string_literal: true

require "spec_helper"

RSpec.describe Airwallex::BillingCustomer do

  describe ".resource_path" do
    it "returns correct path" do
      expect(described_class.resource_path).to eq("/api/v1/billing/billing_customers")
    end
  end

  describe ".create" do
    # Flat payload, no wrapper key (unlike Beneficiary/ConnectedAccount).
    let(:create_params) do
      {
        name: "Acme Corp",
        email: "billing@acme.example",
        type: "BUSINESS",
        default_billing_currency: "AUD",
        default_legal_entity_id: "le_test123",
        address: {
          street: "200 Collins Street",
          city: "Melbourne",
          state: "VIC",
          postcode: "3000",
          country_code: "AU"
        }
      }
    end

    before do
      stub_request(:post, "#{BASE_URL}/api/v1/billing/billing_customers/create")
        .with(body: hash_including(create_params))
        .to_return(
          status: 200,
          body: { id: "bcus_123" }.merge(create_params).to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "creates a billing customer" do
      customer = described_class.create(create_params)

      expect(customer).to be_a(described_class)
      expect(customer.id).to eq("bcus_123")
    end
  end

  describe ".retrieve" do
    before do
      stub_request(:get, "#{BASE_URL}/api/v1/billing/billing_customers/bcus_123")
        .to_return(
          status: 200,
          body: { id: "bcus_123", email: "john@example.com" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "retrieves a billing customer by id" do
      customer = described_class.retrieve("bcus_123")

      expect(customer.id).to eq("bcus_123")
    end
  end

  describe ".list" do
    before do
      stub_request(:get, "#{BASE_URL}/api/v1/billing/billing_customers")
        .to_return(
          status: 200,
          body: {
            items: [
              { id: "bcus_1", email: "john@example.com" },
              { id: "bcus_2", email: "jane@example.com" }
            ],
            has_more: false
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "lists billing customers" do
      customers = described_class.list

      expect(customers).to be_a(Airwallex::ListObject)
      expect(customers.size).to eq(2)
      expect(customers.first.id).to eq("bcus_1")
    end
  end

  describe "#update" do
    let(:customer) { described_class.new(id: "bcus_123", email: "john@example.com") }

    before do
      stub_request(:post, "#{BASE_URL}/api/v1/billing/billing_customers/bcus_123/update")
        .with(body: hash_including(email: "newemail@example.com"))
        .to_return(
          status: 200,
          body: { id: "bcus_123", email: "newemail@example.com" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "updates the billing customer" do
      result = customer.update(email: "newemail@example.com")

      expect(result).to eq(customer)
      expect(customer.email).to eq("newemail@example.com")
    end
  end

  describe "#bank_transfer_instructions" do
    let(:customer) { described_class.new(id: "bcus_123") }

    before do
      stub_request(:get, "#{BASE_URL}/api/v1/billing/billing_customers/bcus_123/bank_transfer_instructions")
        .to_return(
          status: 200,
          body: {
            account_name: "Airwallex Pty Ltd",
            account_number: "12345678",
            reference: "BCUS123"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "retrieves bank transfer instructions for funding subscriptions" do
      instructions = customer.bank_transfer_instructions

      expect(instructions[:reference]).to eq("BCUS123")
    end
  end
end
