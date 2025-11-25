# frozen_string_literal: true

require "spec_helper"

RSpec.describe Airwallex::Quote do
  before do
    stub_request(:post, "https://api-demo.airwallex.com/api/v1/authentication/login")
      .to_return(
        status: 200,
        body: { token: "test_token", expires_at: (Time.now + 3600).iso8601 }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  describe ".create" do
    it "creates quote with sell_amount" do
      stub_request(:post, "https://api-demo.airwallex.com/api/v1/fx/quotes/create")
        .with(body: hash_including(
          from_currency: "USD",
          to_currency: "EUR",
          sell_amount: 1000.00
        ))
        .to_return(
          status: 200,
          body: {
            id: "quote_123456",
            from_currency: "USD",
            to_currency: "EUR",
            sell_amount: 1000.00,
            buy_amount: 850.00,
            exchange_rate: 0.85,
            created_at: "2025-11-25T10:00:00Z",
            expires_at: "2025-11-25T10:00:30Z"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      quote = described_class.create(
        from_currency: "USD",
        to_currency: "EUR",
        sell_amount: 1000.00
      )

      expect(quote).to be_a(Airwallex::Quote)
      expect(quote.id).to eq("quote_123456")
      expect(quote.from_currency).to eq("USD")
      expect(quote.to_currency).to eq("EUR")
      expect(quote.sell_amount).to eq(1000.00)
      expect(quote.buy_amount).to eq(850.00)
      expect(quote.exchange_rate).to eq(0.85)
    end

    it "creates quote with buy_amount" do
      stub_request(:post, "https://api-demo.airwallex.com/api/v1/fx/quotes/create")
        .with(body: hash_including(
          from_currency: "GBP",
          to_currency: "JPY",
          buy_amount: 100000.00
        ))
        .to_return(
          status: 200,
          body: {
            id: "quote_789012",
            from_currency: "GBP",
            to_currency: "JPY",
            sell_amount: 530.50,
            buy_amount: 100000.00,
            exchange_rate: 188.50,
            created_at: "2025-11-25T10:00:00Z",
            expires_at: "2025-11-25T10:01:00Z"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      quote = described_class.create(
        from_currency: "GBP",
        to_currency: "JPY",
        buy_amount: 100000.00
      )

      expect(quote.id).to eq("quote_789012")
      expect(quote.sell_amount).to eq(530.50)
      expect(quote.buy_amount).to eq(100000.00)
    end
  end

  describe ".retrieve" do
    it "retrieves existing quote" do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/fx/quotes/quote_123456")
        .to_return(
          status: 200,
          body: {
            id: "quote_123456",
            from_currency: "USD",
            to_currency: "EUR",
            sell_amount: 1000.00,
            buy_amount: 850.00,
            exchange_rate: 0.85,
            created_at: "2025-11-25T10:00:00Z",
            expires_at: "2025-11-25T10:00:30Z"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      quote = described_class.retrieve("quote_123456")

      expect(quote.id).to eq("quote_123456")
      expect(quote.from_currency).to eq("USD")
      expect(quote.exchange_rate).to eq(0.85)
    end
  end

  describe "#expired?" do
    it "returns false for active quote" do
      quote = described_class.new(
        id: "quote_123",
        expires_at: (Time.now + 30).iso8601
      )

      expect(quote.expired?).to be false
    end

    it "returns true for expired quote" do
      quote = described_class.new(
        id: "quote_123",
        expires_at: (Time.now - 10).iso8601
      )

      expect(quote.expired?).to be true
    end

    it "returns false when expires_at is nil" do
      quote = described_class.new(id: "quote_123")

      expect(quote.expired?).to be false
    end
  end

  describe "#seconds_until_expiration" do
    it "returns seconds remaining" do
      future_time = Time.now + 45
      quote = described_class.new(
        id: "quote_123",
        expires_at: future_time.iso8601
      )

      seconds = quote.seconds_until_expiration

      expect(seconds).to be_within(2).of(45)
    end

    it "returns 0 for expired quote" do
      quote = described_class.new(
        id: "quote_123",
        expires_at: (Time.now - 10).iso8601
      )

      expect(quote.seconds_until_expiration).to eq(0)
    end

    it "returns nil when expires_at is nil" do
      quote = described_class.new(id: "quote_123")

      expect(quote.seconds_until_expiration).to be_nil
    end
  end

  describe "error handling" do
    it "handles expired quote on creation" do
      stub_request(:post, "https://api-demo.airwallex.com/api/v1/fx/quotes/create")
        .to_return(
          status: 400,
          body: {
            code: "quote_expired",
            message: "Quote has expired"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect do
        described_class.create(
          from_currency: "USD",
          to_currency: "EUR",
          sell_amount: 1000.00
        )
      end.to raise_error(Airwallex::BadRequestError, /expired/)
    end

    it "handles missing amount parameter" do
      stub_request(:post, "https://api-demo.airwallex.com/api/v1/fx/quotes/create")
        .to_return(
          status: 400,
          body: {
            code: "invalid_request",
            message: "Either sell_amount or buy_amount must be provided"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect do
        described_class.create(
          from_currency: "USD",
          to_currency: "EUR"
        )
      end.to raise_error(Airwallex::BadRequestError, /must be provided/)
    end

    it "handles quote not found" do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/fx/quotes/nonexistent")
        .to_return(
          status: 404,
          body: {
            code: "resource_not_found",
            message: "Quote not found"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect do
        described_class.retrieve("nonexistent")
      end.to raise_error(Airwallex::NotFoundError, /not found/)
    end
  end
end
