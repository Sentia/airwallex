# frozen_string_literal: true

require "spec_helper"

RSpec.describe Airwallex::Balance do
  before do
    stub_request(:post, "https://api-demo.airwallex.com/api/v1/authentication/login")
      .to_return(
        status: 200,
        body: { token: "test_token", expires_at: (Time.now + 3600).iso8601 }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  describe ".list" do
    it "lists all balances" do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/balances/current")
        .to_return(
          status: 200,
          body: {
            items: [
              {
                currency: "USD",
                available_amount: 10000.50,
                pending_amount: 500.00,
                reserved_amount: 100.00,
                total_amount: 10600.50
              },
              {
                currency: "EUR",
                available_amount: 8500.75,
                pending_amount: 200.00,
                reserved_amount: 50.00,
                total_amount: 8750.75
              },
              {
                currency: "GBP",
                available_amount: 5000.00,
                pending_amount: 0.00,
                reserved_amount: 0.00,
                total_amount: 5000.00
              }
            ],
            has_more: false
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      balances = described_class.list

      expect(balances).to be_a(Airwallex::ListObject)
      expect(balances.size).to eq(3)
      expect(balances.first.currency).to eq("USD")
      expect(balances.first.available_amount).to eq(10000.50)
      expect(balances.first.total_amount).to eq(10600.50)
    end

    it "filters balances by currency" do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/balances/current")
        .with(query: hash_including(currency: "USD"))
        .to_return(
          status: 200,
          body: {
            items: [
              {
                currency: "USD",
                available_amount: 10000.50,
                total_amount: 10600.50
              }
            ],
            has_more: false
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      balances = described_class.list(currency: "USD")

      expect(balances.size).to eq(1)
      expect(balances.first.currency).to eq("USD")
    end
  end

  describe ".retrieve" do
    it "retrieves balance for specific currency" do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/balances/current")
        .with(query: { currency: "USD" })
        .to_return(
          status: 200,
          body: [
            {
              currency: "USD",
              available_amount: 10000.50,
              pending_amount: 500.00,
              reserved_amount: 100.00,
              total_amount: 10600.50
            }
          ].to_json,
          headers: { "Content-Type" => "application/json" }
        )

      balance = described_class.retrieve("USD")

      expect(balance).to be_a(Airwallex::Balance)
      expect(balance.currency).to eq("USD")
      expect(balance.available_amount).to eq(10000.50)
      expect(balance.pending_amount).to eq(500.00)
      expect(balance.reserved_amount).to eq(100.00)
      expect(balance.total_amount).to eq(10600.50)
    end

    it "retrieves balance with zero amounts" do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/balances/current")
        .with(query: { currency: "JPY" })
        .to_return(
          status: 200,
          body: [
            {
              currency: "JPY",
              available_amount: 0.00,
              pending_amount: 0.00,
              reserved_amount: 0.00,
              total_amount: 0.00
            }
          ].to_json,
          headers: { "Content-Type" => "application/json" }
        )

      balance = described_class.retrieve("JPY")

      expect(balance.currency).to eq("JPY")
      expect(balance.total_amount).to eq(0.00)
    end
  end

  describe "#total_amount" do
    it "calculates total from components" do
      balance = described_class.new(
        currency: "USD",
        available_amount: 1000.00,
        pending_amount: 200.00,
        reserved_amount: 50.00
      )

      expect(balance.total_amount).to eq(1250.00)
    end

    it "handles zero values" do
      balance = described_class.new(
        currency: "EUR",
        available_amount: 500.00,
        pending_amount: 0.00,
        reserved_amount: 0.00
      )

      expect(balance.total_amount).to eq(500.00)
    end

    it "handles missing values" do
      balance = described_class.new(
        currency: "GBP",
        available_amount: 100.00
      )

      expect(balance.total_amount).to eq(100.00)
    end
  end

  describe "error handling" do
    it "handles invalid currency code" do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/balances/current")
        .with(query: { currency: "XXX" })
        .to_return(
          status: 400,
          body: {
            code: "invalid_currency",
            message: "Invalid currency code: XXX"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect do
        described_class.retrieve("XXX")
      end.to raise_error(Airwallex::BadRequestError, /Invalid currency code/)
    end

    it "handles currency not found" do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/balances/current")
        .with(query: { currency: "AUD" })
        .to_return(
          status: 200,
          body: {
            items: [],
            has_more: false
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect do
        described_class.retrieve("AUD")
      end.to raise_error(Airwallex::NotFoundError, /Balance not found/)
    end

    it "handles SCA required error" do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/balances/current")
        .to_return(
          status: 400,
          body: {
            code: "sca_required",
            message: "Strong customer authentication required"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect do
        described_class.list
      end.to raise_error(Airwallex::BadRequestError, /authentication required/)
    end
  end
end
