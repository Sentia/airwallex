# frozen_string_literal: true

require "spec_helper"

RSpec.describe Airwallex::Rate do
  before do
    stub_request(:post, "https://api-demo.airwallex.com/api/v1/authentication/login")
      .to_return(
        status: 200,
        body: { token: "test_token", expires_at: (Time.now + 3600).iso8601 }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  describe ".retrieve" do
    it "retrieves rate for currency pair" do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/fx/rates/current")
        .with(query: { from_currency: "USD", to_currency: "EUR" })
        .to_return(
          status: 200,
          body: {
            from_currency: "USD",
            to_currency: "EUR",
            rate: 0.85,
            inverse_rate: 1.176471,
            timestamp: "2025-11-25T10:00:00Z"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      rate = described_class.retrieve(from_currency: "USD", to_currency: "EUR")

      expect(rate).to be_a(Airwallex::Rate)
      expect(rate.from_currency).to eq("USD")
      expect(rate.to_currency).to eq("EUR")
      expect(rate.rate).to eq(0.85)
      expect(rate.inverse_rate).to eq(1.176471)
    end

    it "retrieves rate with different currency pair" do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/fx/rates/current")
        .with(query: { from_currency: "GBP", to_currency: "JPY" })
        .to_return(
          status: 200,
          body: {
            from_currency: "GBP",
            to_currency: "JPY",
            rate: 188.50
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      rate = described_class.retrieve(from_currency: "GBP", to_currency: "JPY")

      expect(rate.from_currency).to eq("GBP")
      expect(rate.to_currency).to eq("JPY")
      expect(rate.rate).to eq(188.50)
    end
  end

  describe ".list" do
    it "lists multiple rates" do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/fx/rates/current")
        .with(query: hash_including(from_currency: "USD"))
        .to_return(
          status: 200,
          body: {
            items: [
              { from_currency: "USD", to_currency: "EUR", rate: 0.85 },
              { from_currency: "USD", to_currency: "GBP", rate: 0.73 },
              { from_currency: "USD", to_currency: "JPY", rate: 150.25 }
            ],
            has_more: false
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      rates = described_class.list(from_currency: "USD")

      expect(rates).to be_a(Airwallex::ListObject)
      expect(rates.size).to eq(3)
      expect(rates.first.to_currency).to eq("EUR")
    end

    it "filters rates by to_currencies" do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/fx/rates/current")
        .with(query: hash_including(
          from_currency: "USD",
          to_currencies: "EUR,GBP"
        ))
        .to_return(
          status: 200,
          body: {
            items: [
              { from_currency: "USD", to_currency: "EUR", rate: 0.85 },
              { from_currency: "USD", to_currency: "GBP", rate: 0.73 }
            ],
            has_more: false
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      rates = described_class.list(
        from_currency: "USD",
        to_currencies: "EUR,GBP"
      )

      expect(rates.size).to eq(2)
    end
  end

  describe "error handling" do
    it "handles invalid currency code" do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/fx/rates/current")
        .with(query: { from_currency: "XXX", to_currency: "EUR" })
        .to_return(
          status: 400,
          body: {
            code: "invalid_currency",
            message: "Invalid currency code: XXX"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect do
        described_class.retrieve(from_currency: "XXX", to_currency: "EUR")
      end.to raise_error(Airwallex::BadRequestError, /Invalid currency code/)
    end

    it "handles unsupported currency pair" do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/fx/rates/current")
        .with(query: { from_currency: "USD", to_currency: "BTC" })
        .to_return(
          status: 400,
          body: {
            code: "unsupported_currency_pair",
            message: "Currency pair USD/BTC is not supported"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect do
        described_class.retrieve(from_currency: "USD", to_currency: "BTC")
      end.to raise_error(Airwallex::BadRequestError, /not supported/)
    end
  end
end
