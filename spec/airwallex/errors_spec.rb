# frozen_string_literal: true

RSpec.describe Airwallex::Error do
  describe ".from_response" do
    let(:response) { double("response", status: status, body: body) }

    context "with 400 status" do
      let(:status) { 400 }
      let(:body) { '{"code":"invalid_argument","message":"Invalid field"}' }

      it "returns BadRequestError" do
        error = described_class.from_response(response)
        expect(error).to be_a(Airwallex::BadRequestError)
      end
    end

    context "with 401 status" do
      let(:status) { 401 }
      let(:body) { '{"code":"authentication_failed","message":"Invalid credentials"}' }

      it "returns AuthenticationError" do
        error = described_class.from_response(response)
        expect(error).to be_a(Airwallex::AuthenticationError)
      end
    end

    context "with 403 status" do
      let(:status) { 403 }
      let(:body) { '{"code":"permission_denied","message":"Access denied"}' }

      it "returns PermissionError" do
        error = described_class.from_response(response)
        expect(error).to be_a(Airwallex::PermissionError)
      end
    end

    context "with 404 status" do
      let(:status) { 404 }
      let(:body) { '{"code":"not_found","message":"Resource not found"}' }

      it "returns NotFoundError" do
        error = described_class.from_response(response)
        expect(error).to be_a(Airwallex::NotFoundError)
      end
    end

    context "with 429 status" do
      let(:status) { 429 }
      let(:body) { '{"code":"rate_limit_exceeded","message":"Too many requests"}' }

      it "returns RateLimitError" do
        error = described_class.from_response(response)
        expect(error).to be_a(Airwallex::RateLimitError)
      end
    end

    context "with 500 status" do
      let(:status) { 500 }
      let(:body) { '{"code":"internal_error","message":"Server error"}' }

      it "returns APIError" do
        error = described_class.from_response(response)
        expect(error).to be_a(Airwallex::APIError)
      end
    end

    context "with simple error format" do
      let(:status) { 400 }
      let(:body) { '{"code":"insufficient_fund","message":"Not enough balance","source":"charge"}' }

      it "parses code" do
        error = described_class.from_response(response)
        expect(error.code).to eq("insufficient_fund")
      end

      it "parses message" do
        error = described_class.from_response(response)
        expect(error.message).to eq("Not enough balance")
      end

      it "parses param from source" do
        error = described_class.from_response(response)
        expect(error.param).to eq("charge")
      end
    end

    context "with complex error format" do
      let(:status) { 400 }
      let(:body) do
        '{
          "code":"request_id_duplicate",
          "message":"Request ID already used",
          "details":[{"field":"request_id","issue":"duplicate"}]
        }'
      end

      it "parses details array" do
        error = described_class.from_response(response)
        expect(error.details).to be_an(Array)
        expect(error.details.first["field"]).to eq("request_id")
      end
    end

    context "with nested source format" do
      let(:status) { 400 }
      let(:body) do
        '{
          "code":"invalid_argument",
          "message":"Invalid nested field",
          "source":"individual.employers.business_identifiers.type"
        }'
      end

      it "parses nested param path" do
        error = described_class.from_response(response)
        expect(error.param).to eq("individual.employers.business_identifiers.type")
      end
    end

    context "with invalid JSON" do
      let(:status) { 500 }
      let(:body) { "Not JSON" }

      it "handles parse error gracefully" do
        error = described_class.from_response(response)
        expect(error.message).to eq("Not JSON")
        expect(error.code).to be_nil
      end
    end

    context "with empty body" do
      let(:status) { 500 }
      let(:body) { "" }

      it "handles empty body" do
        error = described_class.from_response(response)
        expect(error).to be_a(Airwallex::APIError)
      end
    end
  end

  describe "#initialize" do
    it "accepts all error attributes" do
      error = described_class.new(
        "Test message",
        code: "test_code",
        param: "test_param",
        details: [{ "test" => "detail" }],
        http_status: 400
      )

      expect(error.message).to eq("Test message")
      expect(error.code).to eq("test_code")
      expect(error.param).to eq("test_param")
      expect(error.details).to eq([{ "test" => "detail" }])
      expect(error.http_status).to eq(400)
    end
  end
end
