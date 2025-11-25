# frozen_string_literal: true

require "spec_helper"

RSpec.describe Airwallex::APIOperations::Create do
  let(:test_class) do
    Class.new(Airwallex::APIResource) do
      extend Airwallex::APIOperations::Create

      def self.resource_path
        "/api/v1/test_resources"
      end
    end
  end

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

    stub_const("TestResource", test_class)
  end

  describe ".create" do
    let(:create_params) do
      {
        name: "Test Item",
        value: 100,
        request_id: "req_123"
      }
    end

    let(:create_response) do
      {
        id: "test_123",
        name: "Test Item",
        value: 100
      }
    end

    before do
      stub_request(:post, "https://api-demo.airwallex.com/api/v1/test_resources/create")
        .with(body: hash_including(create_params))
        .to_return(
          status: 200,
          body: create_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "creates resource" do
      resource = TestResource.create(create_params)

      expect(resource).to be_a(TestResource)
      expect(resource.id).to eq("test_123")
      expect(resource.name).to eq("Test Item")
      expect(resource.value).to eq(100)
    end

    it "sends POST request to create endpoint" do
      TestResource.create(create_params)

      expect(WebMock).to have_requested(:post, "https://api-demo.airwallex.com/api/v1/test_resources/create")
        .with(body: hash_including(create_params))
    end

    it "returns instance of calling class" do
      resource = TestResource.create(create_params)

      expect(resource.class).to eq(TestResource)
    end
  end
end
