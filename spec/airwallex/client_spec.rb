# frozen_string_literal: true

RSpec.describe Airwallex::Client do
  let(:config) do
    Airwallex::Configuration.new.tap do |c|
      c.api_key = "test_api_key"
      c.client_id = "test_client_id"
      c.environment = :sandbox
    end
  end

  subject(:client) { described_class.new(config) }

  describe "#initialize" do
    it "requires valid configuration" do
      invalid_config = Airwallex::Configuration.new
      expect { described_class.new(invalid_config) }.to raise_error(Airwallex::ConfigurationError)
    end

    it "initializes with valid configuration" do
      expect(client).to be_a(described_class)
    end
  end

  describe "#authenticate!" do
    let(:success_response) do
      {
        status: 200,
        body: { token: "test_token_123" }.to_json,
        headers: { "Content-Type" => "application/json" }
      }
    end

    before do
      stub_request(:post, "https://api-demo.airwallex.com/api/v1/authentication/login")
        .to_return(success_response)
    end

    it "exchanges credentials for access token" do
      token = client.authenticate!
      expect(token).to eq("test_token_123")
    end

    it "stores access token" do
      client.authenticate!
      expect(client.access_token).to eq("test_token_123")
    end

    it "stores token expiration time" do
      client.authenticate!
      expect(client.token_expires_at).to be_a(Time)
      expect(client.token_expires_at).to be > Time.now
    end

    it "sends correct headers" do
      stub = stub_request(:post, "https://api-demo.airwallex.com/api/v1/authentication/login")
        .with(
          headers: {
            "x-client-id" => "test_client_id",
            "x-api-key" => "test_api_key"
          }
        )
        .to_return(success_response)

      client.authenticate!
      expect(stub).to have_been_requested
    end

    context "with invalid credentials" do
      let(:error_response) do
        {
          status: 401,
          body: { code: "authentication_failed", message: "Invalid credentials" }.to_json,
          headers: { "Content-Type" => "application/json" }
        }
      end

      before do
        stub_request(:post, "https://api-demo.airwallex.com/api/v1/authentication/login")
          .to_return(error_response)
      end

      it "raises AuthenticationError" do
        expect { client.authenticate! }.to raise_error(Airwallex::AuthenticationError)
      end
    end
  end

  describe "#token_expired?" do
    it "returns true when token is nil" do
      expect(client.token_expired?).to be true
    end

    it "returns false when token is valid" do
      client.instance_variable_set(:@access_token, "token")
      client.instance_variable_set(:@token_expires_at, Time.now + 600)
      expect(client.token_expired?).to be false
    end

    it "returns true when token is near expiration" do
      client.instance_variable_set(:@access_token, "token")
      client.instance_variable_set(:@token_expires_at, Time.now + 60) # 1 minute left
      expect(client.token_expired?).to be true
    end
  end

  describe "#ensure_authenticated!" do
    let(:success_response) do
      {
        status: 200,
        body: { token: "test_token_123", expires_at: (Time.now + 1800).to_i }.to_json,
        headers: { "Content-Type" => "application/json" }
      }
    end

    before do
      stub_request(:post, "https://api-demo.airwallex.com/api/v1/authentication/login")
        .to_return(success_response)
    end

    it "authenticates when token is expired" do
      expect(client.access_token).to be_nil
      client.ensure_authenticated!
      expect(client.access_token).to eq("test_token_123")
    end

    it "does not re-authenticate when token is valid" do
      client.instance_variable_set(:@access_token, "existing_token")
      client.instance_variable_set(:@token_expires_at, Time.now + 600)

      client.ensure_authenticated!
      expect(client.access_token).to eq("existing_token")
    end
  end

  describe "#connection" do
    it "creates Faraday connection" do
      expect(client.connection).to be_a(Faraday::Connection)
    end

    it "sets correct base URL" do
      expect(client.connection.url_prefix.to_s).to eq("https://api-demo.airwallex.com/")
    end

    it "includes required headers" do
      headers = client.connection.headers
      expect(headers["Content-Type"]).to eq("application/json")
      expect(headers["User-Agent"]).to match(/Airwallex-Ruby/)
      expect(headers["x-api-version"]).to eq("2024-09-27")
    end
  end

  describe "HTTP methods" do
    describe "#get" do
      it "responds to get" do
        expect(client).to respond_to(:get)
      end
    end

    describe "#post" do
      it "responds to post" do
        expect(client).to respond_to(:post)
      end
    end

    describe "#put" do
      it "responds to put" do
        expect(client).to respond_to(:put)
      end
    end

    describe "#patch" do
      it "responds to patch" do
        expect(client).to respond_to(:patch)
      end
    end

    describe "#delete" do
      it "responds to delete" do
        expect(client).to respond_to(:delete)
      end
    end
  end

  describe "#user_agent" do
    it "includes gem version" do
      user_agent = client.send(:user_agent)
      expect(user_agent).to include("Airwallex-Ruby/#{Airwallex::VERSION}")
    end

    it "includes Ruby version" do
      user_agent = client.send(:user_agent)
      expect(user_agent).to include("Ruby/#{RUBY_VERSION}")
    end
  end
end
