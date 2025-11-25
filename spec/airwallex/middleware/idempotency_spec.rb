# frozen_string_literal: true

RSpec.describe Airwallex::Middleware::Idempotency do
  let(:app) { double("app") }
  let(:middleware) { described_class.new(app) }

  describe "#call" do
    context "with POST request" do
      let(:env) do
        {
          method: :post,
          body: { amount: 100 }
        }
      end

      it "injects request_id when missing" do
        expect(app).to receive(:call) do |passed_env|
          expect(passed_env[:body][:request_id]).to be_a(String)
          expect(passed_env[:body][:request_id]).to match(/\A[0-9a-f-]{36}\z/)
        end

        middleware.call(env)
      end

      it "preserves existing request_id" do
        env[:body][:request_id] = "my_custom_id"

        expect(app).to receive(:call) do |passed_env|
          expect(passed_env[:body][:request_id]).to eq("my_custom_id")
        end

        middleware.call(env)
      end

      it "preserves existing request_id as string key" do
        env[:body]["request_id"] = "my_custom_id"

        expect(app).to receive(:call) do |passed_env|
          expect(passed_env[:body]["request_id"]).to eq("my_custom_id")
        end

        middleware.call(env)
      end
    end

    context "with PUT request" do
      let(:env) do
        {
          method: :put,
          body: { field: "value" }
        }
      end

      it "injects request_id" do
        expect(app).to receive(:call) do |passed_env|
          expect(passed_env[:body][:request_id]).to be_a(String)
        end

        middleware.call(env)
      end
    end

    context "with PATCH request" do
      let(:env) do
        {
          method: :patch,
          body: { field: "value" }
        }
      end

      it "injects request_id" do
        expect(app).to receive(:call) do |passed_env|
          expect(passed_env[:body][:request_id]).to be_a(String)
        end

        middleware.call(env)
      end
    end

    context "with GET request" do
      let(:env) do
        {
          method: :get,
          body: nil
        }
      end

      it "does not inject request_id" do
        expect(app).to receive(:call).with(env)
        middleware.call(env)
      end
    end

    context "with non-hash body" do
      let(:env) do
        {
          method: :post,
          body: "string body"
        }
      end

      it "does not inject request_id" do
        expect(app).to receive(:call).with(env)
        middleware.call(env)
      end
    end
  end
end
