# frozen_string_literal: true

require "spec_helper"

RSpec.describe Airwallex::PaymentMethod do
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
      expect(described_class.resource_path).to eq("/api/v1/pa/payment_methods")
    end
  end

  describe ".create" do
    let(:create_params) do
      {
        type: "card",
        card: {
          number: "4242424242424242",
          expiry_month: "12",
          expiry_year: "2025",
          cvc: "123"
        },
        billing: {
          first_name: "John",
          last_name: "Doe",
          email: "john@example.com"
        }
      }
    end

    let(:payment_method_response) do
      {
        id: "pm_123",
        type: "card",
        card: {
          brand: "visa",
          last4: "4242",
          expiry_month: "12",
          expiry_year: "2025",
          country: "US"
        },
        billing: {
          first_name: "John",
          last_name: "Doe",
          email: "john@example.com"
        },
        customer_id: "cus_123",
        created_at: "2025-11-25T10:00:00Z"
      }
    end

    before do
      stub_request(:post, "https://api-demo.airwallex.com/api/v1/pa/payment_methods/create")
        .with(body: hash_including(type: "card"))
        .to_return(
          status: 200,
          body: payment_method_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "creates payment method" do
      pm = described_class.create(create_params)

      expect(pm).to be_a(described_class)
      expect(pm.id).to eq("pm_123")
      expect(pm.type).to eq("card")
      expect(pm.card[:last4]).to eq("4242")
      expect(pm.card[:brand]).to eq("visa")
    end

    it "sends POST request to correct endpoint" do
      described_class.create(create_params)

      expect(WebMock).to have_requested(:post, "https://api-demo.airwallex.com/api/v1/pa/payment_methods/create")
    end

    it "does not return full card number on creation" do
      pm = described_class.create(create_params)

      expect(pm.card).not_to have_key(:number)
      expect(pm.card[:last4]).to eq("4242")
    end
  end

  describe ".retrieve" do
    let(:payment_method_response) do
      {
        id: "pm_123",
        type: "card",
        card: {
          brand: "visa",
          last4: "4242",
          expiry_month: "12",
          expiry_year: "2025"
        },
        customer_id: "cus_123"
      }
    end

    before do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/pa/payment_methods/pm_123")
        .to_return(
          status: 200,
          body: payment_method_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "retrieves payment method by id" do
      pm = described_class.retrieve("pm_123")

      expect(pm).to be_a(described_class)
      expect(pm.id).to eq("pm_123")
      expect(pm.type).to eq("card")
    end

    it "only returns last4 for security" do
      pm = described_class.retrieve("pm_123")

      expect(pm.card).not_to have_key(:number)
      expect(pm.card).not_to have_key(:cvc)
      expect(pm.card[:last4]).to eq("4242")
    end
  end

  describe ".list" do
    let(:list_response) do
      {
        items: [
          { id: "pm_1", type: "card", card: { last4: "4242", brand: "visa" }, customer_id: "cus_123" },
          { id: "pm_2", type: "card", card: { last4: "5555", brand: "mastercard" }, customer_id: "cus_123" }
        ],
        has_more: false
      }
    end

    before do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/pa/payment_methods")
        .with(query: { customer_id: "cus_123", page_size: 10 })
        .to_return(
          status: 200,
          body: list_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "lists payment methods" do
      list = described_class.list(customer_id: "cus_123", page_size: 10)

      expect(list).to be_a(Airwallex::ListObject)
      expect(list.size).to eq(2)
      expect(list.first.id).to eq("pm_1")
      expect(list.last.id).to eq("pm_2")
    end

    it "filters by customer_id" do
      described_class.list(customer_id: "cus_123", page_size: 10)

      expect(WebMock).to have_requested(:get, "https://api-demo.airwallex.com/api/v1/pa/payment_methods")
        .with(query: hash_including(customer_id: "cus_123"))
    end

    it "returns ListObject with resources" do
      list = described_class.list(customer_id: "cus_123", page_size: 10)

      expect(list.data).to all(be_a(described_class))
    end
  end

  describe ".update" do
    let(:update_params) do
      {
        billing: {
          address: {
            city: "New York",
            postal_code: "10001"
          }
        }
      }
    end

    let(:updated_response) do
      {
        id: "pm_123",
        type: "card",
        card: { last4: "4242", brand: "visa" },
        billing: {
          first_name: "John",
          address: {
            city: "New York",
            postal_code: "10001"
          }
        }
      }
    end

    before do
      stub_request(:put, "https://api-demo.airwallex.com/api/v1/pa/payment_methods/pm_123")
        .to_return(
          status: 200,
          body: updated_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "updates payment method" do
      pm = described_class.update("pm_123", update_params)

      expect(pm).to be_a(described_class)
      expect(pm.id).to eq("pm_123")
      expect(pm.billing[:address][:postal_code]).to eq("10001")
    end
  end

  describe "#update" do
    let(:pm) do
      described_class.new(
        id: "pm_123",
        type: "card",
        card: { last4: "4242" },
        billing: { first_name: "John" }
      )
    end

    let(:updated_response) do
      {
        id: "pm_123",
        type: "card",
        card: { last4: "4242" },
        billing: { first_name: "Jane" }
      }
    end

    before do
      stub_request(:put, "https://api-demo.airwallex.com/api/v1/pa/payment_methods/pm_123")
        .to_return(
          status: 200,
          body: updated_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "updates instance" do
      result = pm.update(billing: { first_name: "Jane" })

      expect(result).to eq(pm)
      expect(pm.billing[:first_name]).to eq("Jane")
    end
  end

  describe ".delete" do
    before do
      stub_request(:delete, "https://api-demo.airwallex.com/api/v1/pa/payment_methods/pm_123")
        .to_return(
          status: 200,
          body: {}.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "deletes payment method" do
      result = described_class.delete("pm_123")

      expect(result).to be true
    end

    it "sends DELETE request" do
      described_class.delete("pm_123")

      expect(WebMock).to have_requested(:delete, "https://api-demo.airwallex.com/api/v1/pa/payment_methods/pm_123")
    end
  end

  describe "#detach" do
    let(:pm) do
      described_class.new(
        id: "pm_123",
        customer_id: "cus_123",
        type: "card"
      )
    end

    let(:detached_response) do
      {
        id: "pm_123",
        customer_id: nil,
        type: "card"
      }
    end

    before do
      stub_request(:post, "https://api-demo.airwallex.com/api/v1/pa/payment_methods/pm_123/detach")
        .to_return(
          status: 200,
          body: detached_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "detaches payment method from customer" do
      result = pm.detach

      expect(result).to eq(pm)
      expect(pm.customer_id).to be_nil
    end

    it "sends POST request to detach endpoint" do
      pm.detach

      expect(WebMock).to have_requested(:post, "https://api-demo.airwallex.com/api/v1/pa/payment_methods/pm_123/detach")
    end
  end
end
