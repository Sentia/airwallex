# frozen_string_literal: true

RSpec.describe Airwallex::Middleware::AuthRefresh do
  let(:app) { double("app") }

  let(:client) do
    Class.new do
      attr_reader :access_token

      def initialize
        @access_token = "token_initial"
        @ensure_authenticated_calls = 0
        @authenticate_calls = 0
      end

      def ensure_authenticated!
        @ensure_authenticated_calls += 1
      end

      def authenticate!
        @authenticate_calls += 1
        @access_token = "token_refreshed"
      end

      def ensure_authenticated_calls
        @ensure_authenticated_calls
      end

      def authenticate_calls
        @authenticate_calls
      end
    end.new
  end

  let(:middleware) { described_class.new(app, client) }

  def env_for(path)
    { url: URI("#{BASE_URL}#{path}"), request_headers: {} }
  end

  def response_double(status)
    double("response", status: status)
  end

  describe "#call" do
    context "with the login endpoint" do
      let(:env) { env_for(LOGIN_PATH) }

      it "does not ensure authentication or set the Authorization header" do
        allow(app).to receive(:call).and_return(response_double(200))

        middleware.call(env)

        expect(client.ensure_authenticated_calls).to eq(0)
        expect(env[:request_headers]).not_to have_key("Authorization")
      end

      it "passes the request straight through" do
        expect(app).to receive(:call).with(env).and_return(response_double(200))

        middleware.call(env)
      end
    end

    context "with a non-authentication endpoint" do
      let(:env) { env_for("/api/v1/pa/payment_intents/create") }

      it "ensures the client is authenticated before the request" do
        allow(app).to receive(:call).and_return(response_double(200))

        middleware.call(env)

        expect(client.ensure_authenticated_calls).to eq(1)
      end

      it "sets the Authorization header from the client's access token" do
        expect(app).to receive(:call) do |passed_env|
          expect(passed_env[:request_headers]["Authorization"]).to eq("Bearer token_initial")
          response_double(200)
        end

        middleware.call(env)
      end

      it "does not re-authenticate on a successful response" do
        allow(app).to receive(:call).and_return(response_double(200))

        middleware.call(env)

        expect(client.authenticate_calls).to eq(0)
      end

      it "re-authenticates and retries once on a 401 response" do
        call_count = 0
        allow(app).to receive(:call) do |passed_env|
          call_count += 1
          if call_count == 1
            response_double(401)
          else
            expect(passed_env[:request_headers]["Authorization"]).to eq("Bearer token_refreshed")
            response_double(200)
          end
        end

        response = middleware.call(env)

        expect(client.authenticate_calls).to eq(1)
        expect(app).to have_received(:call).twice
        expect(response.status).to eq(200)
      end

      it "does not retry more than once if the retried request also returns 401" do
        allow(app).to receive(:call).and_return(response_double(401))

        response = middleware.call(env)

        expect(client.authenticate_calls).to eq(1)
        expect(app).to have_received(:call).twice
        expect(response.status).to eq(401)
      end
    end

    context "with an authentication endpoint that is not login" do
      let(:env) { env_for("/api/v1/authentication/refresh") }

      it "does not call ensure_authenticated! but still sets the Authorization header" do
        expect(app).to receive(:call) do |passed_env|
          expect(passed_env[:request_headers]["Authorization"]).to eq("Bearer token_initial")
          response_double(200)
        end

        middleware.call(env)

        expect(client.ensure_authenticated_calls).to eq(0)
      end
    end
  end
end
