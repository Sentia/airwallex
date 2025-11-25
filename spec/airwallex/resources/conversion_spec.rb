# frozen_string_literal: true

require "spec_helper"

RSpec.describe Airwallex::Conversion do
  before do
    stub_request(:post, "https://api-demo.airwallex.com/api/v1/authentication/login")
      .to_return(
        status: 200,
        body: { token: "test_token", expires_at: (Time.now + 3600).iso8601 }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  describe ".create" do
    it "creates conversion with quote_id" do
      stub_request(:post, "https://api-demo.airwallex.com/api/v1/conversions/create")
        .with(body: hash_including(
          quote_id: "quote_123456",
          request_id: "conv_req_001"
        ))
        .to_return(
          status: 200,
          body: {
            id: "conv_123456",
            quote_id: "quote_123456",
            request_id: "conv_req_001",
            from_currency: "USD",
            to_currency: "EUR",
            sell_amount: 1000.00,
            buy_amount: 850.00,
            exchange_rate: 0.85,
            status: "COMPLETED",
            created_at: "2025-11-25T10:00:00Z"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      conversion = described_class.create(
        quote_id: "quote_123456",
        request_id: "conv_req_001"
      )

      expect(conversion).to be_a(Airwallex::Conversion)
      expect(conversion.id).to eq("conv_123456")
      expect(conversion.quote_id).to eq("quote_123456")
      expect(conversion.request_id).to eq("conv_req_001")
      expect(conversion.from_currency).to eq("USD")
      expect(conversion.to_currency).to eq("EUR")
      expect(conversion.sell_amount).to eq(1000.00)
      expect(conversion.buy_amount).to eq(850.00)
      expect(conversion.exchange_rate).to eq(0.85)
      expect(conversion.status).to eq("COMPLETED")
    end

    it "creates conversion at market rate without quote" do
      stub_request(:post, "https://api-demo.airwallex.com/api/v1/conversions/create")
        .with(body: hash_including(
          from_currency: "GBP",
          to_currency: "JPY",
          sell_amount: 100.00,
          request_id: "conv_req_002"
        ))
        .to_return(
          status: 200,
          body: {
            id: "conv_789012",
            from_currency: "GBP",
            to_currency: "JPY",
            sell_amount: 100.00,
            buy_amount: 18850.00,
            exchange_rate: 188.50,
            status: "COMPLETED",
            created_at: "2025-11-25T10:00:00Z"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      conversion = described_class.create(
        from_currency: "GBP",
        to_currency: "JPY",
        sell_amount: 100.00,
        request_id: "conv_req_002"
      )

      expect(conversion.id).to eq("conv_789012")
      expect(conversion.from_currency).to eq("GBP")
      expect(conversion.to_currency).to eq("JPY")
      expect(conversion.sell_amount).to eq(100.00)
      expect(conversion.exchange_rate).to eq(188.50)
    end

    it "creates conversion with buy_amount" do
      stub_request(:post, "https://api-demo.airwallex.com/api/v1/conversions/create")
        .with(body: hash_including(
          from_currency: "USD",
          to_currency: "EUR",
          buy_amount: 850.00,
          request_id: "conv_req_003"
        ))
        .to_return(
          status: 200,
          body: {
            id: "conv_345678",
            from_currency: "USD",
            to_currency: "EUR",
            sell_amount: 1000.00,
            buy_amount: 850.00,
            exchange_rate: 0.85,
            status: "COMPLETED",
            created_at: "2025-11-25T10:00:00Z"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      conversion = described_class.create(
        from_currency: "USD",
        to_currency: "EUR",
        buy_amount: 850.00,
        request_id: "conv_req_003"
      )

      expect(conversion.sell_amount).to eq(1000.00)
      expect(conversion.buy_amount).to eq(850.00)
    end
  end

  describe ".retrieve" do
    it "retrieves existing conversion" do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/conversions/conv_123456")
        .to_return(
          status: 200,
          body: {
            id: "conv_123456",
            quote_id: "quote_123456",
            from_currency: "USD",
            to_currency: "EUR",
            sell_amount: 1000.00,
            buy_amount: 850.00,
            exchange_rate: 0.85,
            status: "COMPLETED",
            created_at: "2025-11-25T10:00:00Z"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      conversion = described_class.retrieve("conv_123456")

      expect(conversion.id).to eq("conv_123456")
      expect(conversion.quote_id).to eq("quote_123456")
      expect(conversion.status).to eq("COMPLETED")
    end
  end

  describe ".list" do
    it "lists conversions" do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/conversions")
        .to_return(
          status: 200,
          body: {
            items: [
              {
                id: "conv_123456",
                from_currency: "USD",
                to_currency: "EUR",
                status: "COMPLETED"
              },
              {
                id: "conv_789012",
                from_currency: "GBP",
                to_currency: "JPY",
                status: "COMPLETED"
              }
            ],
            has_more: false
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      conversions = described_class.list

      expect(conversions).to be_a(Airwallex::ListObject)
      expect(conversions.size).to eq(2)
      expect(conversions.first.id).to eq("conv_123456")
    end

    it "filters by from_currency" do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/conversions")
        .with(query: hash_including(from_currency: "USD"))
        .to_return(
          status: 200,
          body: {
            items: [
              { id: "conv_123456", from_currency: "USD", status: "COMPLETED" }
            ],
            has_more: false
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      conversions = described_class.list(from_currency: "USD")

      expect(conversions.size).to eq(1)
    end
  end

  describe "error handling" do
    it "handles expired quote" do
      stub_request(:post, "https://api-demo.airwallex.com/api/v1/conversions/create")
        .to_return(
          status: 400,
          body: {
            code: "quote_expired",
            message: "The quote has expired"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect do
        described_class.create(
          quote_id: "expired_quote",
          request_id: "conv_req_001"
        )
      end.to raise_error(Airwallex::BadRequestError, /expired/)
    end

    it "handles insufficient funds" do
      stub_request(:post, "https://api-demo.airwallex.com/api/v1/conversions/create")
        .to_return(
          status: 400,
          body: {
            code: "insufficient_funds",
            message: "Insufficient balance in USD account"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect do
        described_class.create(
          from_currency: "USD",
          to_currency: "EUR",
          sell_amount: 10000.00,
          request_id: "conv_req_001"
        )
      end.to raise_error(Airwallex::BadRequestError, /Insufficient balance/)
    end

    it "handles duplicate request_id" do
      stub_request(:post, "https://api-demo.airwallex.com/api/v1/conversions/create")
        .to_return(
          status: 400,
          body: {
            code: "duplicate_request",
            message: "Request ID already used"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect do
        described_class.create(
          from_currency: "USD",
          to_currency: "EUR",
          sell_amount: 100.00,
          request_id: "duplicate_id"
        )
      end.to raise_error(Airwallex::BadRequestError, /already used/)
    end

    it "handles conversion not found" do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/conversions/nonexistent")
        .to_return(
          status: 404,
          body: {
            code: "resource_not_found",
            message: "Conversion not found"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect do
        described_class.retrieve("nonexistent")
      end.to raise_error(Airwallex::NotFoundError, /not found/)
    end
  end
end
