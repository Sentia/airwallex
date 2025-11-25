# frozen_string_literal: true

require "spec_helper"

RSpec.describe Airwallex::Customer do
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
      expect(described_class.resource_path).to eq("/api/v1/pa/customers")
    end
  end

  describe ".create" do
    let(:create_params) do
      {
        email: "john@example.com",
        first_name: "John",
        last_name: "Doe",
        metadata: { internal_id: "user_789" }
      }
    end

    let(:customer_response) do
      {
        id: "cus_123",
        email: "john@example.com",
        first_name: "John",
        last_name: "Doe",
        metadata: { internal_id: "user_789" },
        created_at: "2025-11-25T10:00:00Z"
      }
    end

    before do
      stub_request(:post, "https://api-demo.airwallex.com/api/v1/pa/customers/create")
        .with(body: hash_including(email: "john@example.com"))
        .to_return(
          status: 200,
          body: customer_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "creates customer" do
      customer = described_class.create(create_params)

      expect(customer).to be_a(described_class)
      expect(customer.id).to eq("cus_123")
      expect(customer.email).to eq("john@example.com")
      expect(customer.first_name).to eq("John")
      expect(customer.metadata[:internal_id]).to eq("user_789")
    end

    it "sends POST request to correct endpoint" do
      described_class.create(create_params)

      expect(WebMock).to have_requested(:post, "https://api-demo.airwallex.com/api/v1/pa/customers/create")
    end
  end

  describe ".retrieve" do
    let(:customer_response) do
      {
        id: "cus_123",
        email: "john@example.com",
        first_name: "John",
        last_name: "Doe"
      }
    end

    before do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/pa/customers/cus_123")
        .to_return(
          status: 200,
          body: customer_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "retrieves customer by id" do
      customer = described_class.retrieve("cus_123")

      expect(customer).to be_a(described_class)
      expect(customer.id).to eq("cus_123")
      expect(customer.email).to eq("john@example.com")
    end
  end

  describe ".list" do
    let(:list_response) do
      {
        items: [
          { id: "cus_1", email: "john@example.com", first_name: "John" },
          { id: "cus_2", email: "jane@example.com", first_name: "Jane" }
        ],
        has_more: false
      }
    end

    before do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/pa/customers")
        .with(query: { page_size: 10 })
        .to_return(
          status: 200,
          body: list_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "lists customers" do
      list = described_class.list(page_size: 10)

      expect(list).to be_a(Airwallex::ListObject)
      expect(list.size).to eq(2)
      expect(list.first.id).to eq("cus_1")
      expect(list.last.id).to eq("cus_2")
    end

    it "returns ListObject with resources" do
      list = described_class.list(page_size: 10)

      expect(list.data).to all(be_a(described_class))
    end
  end

  describe ".update" do
    let(:update_params) do
      {
        email: "newemail@example.com",
        metadata: { updated: true }
      }
    end

    let(:updated_response) do
      {
        id: "cus_123",
        email: "newemail@example.com",
        first_name: "John",
        metadata: { updated: true }
      }
    end

    before do
      stub_request(:put, "https://api-demo.airwallex.com/api/v1/pa/customers/cus_123")
        .to_return(
          status: 200,
          body: updated_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "updates customer" do
      customer = described_class.update("cus_123", update_params)

      expect(customer).to be_a(described_class)
      expect(customer.id).to eq("cus_123")
      expect(customer.email).to eq("newemail@example.com")
    end
  end

  describe "#update" do
    let(:customer) do
      described_class.new(
        id: "cus_123",
        email: "john@example.com",
        first_name: "John"
      )
    end

    let(:updated_response) do
      {
        id: "cus_123",
        email: "john@example.com",
        first_name: "Johnny"
      }
    end

    before do
      stub_request(:put, "https://api-demo.airwallex.com/api/v1/pa/customers/cus_123")
        .to_return(
          status: 200,
          body: updated_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "updates instance" do
      result = customer.update(first_name: "Johnny")

      expect(result).to eq(customer)
      expect(customer.first_name).to eq("Johnny")
    end
  end

  describe ".delete" do
    before do
      stub_request(:delete, "https://api-demo.airwallex.com/api/v1/pa/customers/cus_123")
        .to_return(
          status: 200,
          body: {}.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "deletes customer" do
      result = described_class.delete("cus_123")

      expect(result).to be true
    end

    it "sends DELETE request" do
      described_class.delete("cus_123")

      expect(WebMock).to have_requested(:delete, "https://api-demo.airwallex.com/api/v1/pa/customers/cus_123")
    end
  end

  describe "#payment_methods" do
    let(:customer) do
      described_class.new(id: "cus_123", email: "john@example.com")
    end

    let(:payment_methods_response) do
      {
        items: [
          { id: "pm_1", type: "card", customer_id: "cus_123" },
          { id: "pm_2", type: "card", customer_id: "cus_123" }
        ],
        has_more: false
      }
    end

    before do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/pa/payment_methods")
        .with(query: { customer_id: "cus_123" })
        .to_return(
          status: 200,
          body: payment_methods_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "lists payment methods for customer" do
      methods = customer.payment_methods

      expect(methods).to be_a(Airwallex::ListObject)
      expect(methods.size).to eq(2)
      expect(methods.first.customer_id).to eq("cus_123")
    end

    it "passes customer_id to list call" do
      customer.payment_methods

      expect(WebMock).to have_requested(:get, "https://api-demo.airwallex.com/api/v1/pa/payment_methods")
        .with(query: hash_including(customer_id: "cus_123"))
    end

    it "accepts additional parameters" do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/pa/payment_methods")
        .with(query: { customer_id: "cus_123", type: "card" })
        .to_return(
          status: 200,
          body: payment_methods_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      customer.payment_methods(type: "card")

      expect(WebMock).to have_requested(:get, "https://api-demo.airwallex.com/api/v1/pa/payment_methods")
        .with(query: { customer_id: "cus_123", type: "card" })
    end
  end
end
