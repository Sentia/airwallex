# frozen_string_literal: true

require "spec_helper"

RSpec.describe Airwallex::Rate do

  # sell_currency is what you're giving up, buy_currency is what you're
  # acquiring — "from USD to EUR" means sell_currency: USD, buy_currency: EUR.
  describe ".retrieve" do
    it "retrieves rate for currency pair" do
      stub_request(:get, "#{BASE_URL}/api/v1/fx/rates/current")
        .with(query: { sell_currency: "USD", buy_currency: "EUR" })
        .to_return(
          status: 200,
          body: {
            sell_currency: "USD",
            buy_currency: "EUR",
            rate: 0.85,
            inverse_rate: 1.176471,
            timestamp: "2025-11-25T10:00:00Z"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      rate = described_class.retrieve(sell_currency: "USD", buy_currency: "EUR")

      expect(rate).to be_a(Airwallex::Rate)
      expect(rate.sell_currency).to eq("USD")
      expect(rate.buy_currency).to eq("EUR")
      expect(rate.rate).to eq(0.85)
      expect(rate.inverse_rate).to eq(1.176471)
    end

    it "retrieves rate with different currency pair" do
      stub_request(:get, "#{BASE_URL}/api/v1/fx/rates/current")
        .with(query: { sell_currency: "GBP", buy_currency: "JPY" })
        .to_return(
          status: 200,
          body: {
            sell_currency: "GBP",
            buy_currency: "JPY",
            rate: 188.50
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      rate = described_class.retrieve(sell_currency: "GBP", buy_currency: "JPY")

      expect(rate.sell_currency).to eq("GBP")
      expect(rate.buy_currency).to eq("JPY")
      expect(rate.rate).to eq(188.50)
    end
  end

  it "does not support .list" do
    expect(described_class).not_to respond_to(:list)
  end

  describe "error handling" do
    it "handles invalid currency code" do
      stub_request(:get, "#{BASE_URL}/api/v1/fx/rates/current")
        .with(query: { sell_currency: "XXX", buy_currency: "EUR" })
        .to_return(
          status: 400,
          body: {
            code: "invalid_currency",
            message: "Invalid currency code: XXX"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect do
        described_class.retrieve(sell_currency: "XXX", buy_currency: "EUR")
      end.to raise_error(Airwallex::BadRequestError, /Invalid currency code/)
    end

    it "handles unsupported currency pair" do
      stub_request(:get, "#{BASE_URL}/api/v1/fx/rates/current")
        .with(query: { sell_currency: "USD", buy_currency: "BTC" })
        .to_return(
          status: 400,
          body: {
            code: "unsupported_currency_pair",
            message: "Currency pair USD/BTC is not supported"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect do
        described_class.retrieve(sell_currency: "USD", buy_currency: "BTC")
      end.to raise_error(Airwallex::BadRequestError, /not supported/)
    end
  end
end
