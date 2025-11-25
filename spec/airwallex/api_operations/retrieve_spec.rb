# frozen_string_literal: true

require "spec_helper"

RSpec.describe Airwallex::APIOperations::Retrieve do
  let(:test_class) do
    Class.new(Airwallex::APIResource) do
      extend Airwallex::APIOperations::Retrieve

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

  describe ".retrieve" do
    let(:retrieve_response) do
      {
        id: "test_123",
        name: "Test Item",
        value: 100
      }
    end

    before do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/test_resources/test_123")
        .to_return(
          status: 200,
          body: retrieve_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "retrieves resource by id" do
      resource = TestResource.retrieve("test_123")

      expect(resource).to be_a(TestResource)
      expect(resource.id).to eq("test_123")
      expect(resource.name).to eq("Test Item")
      expect(resource.value).to eq(100)
    end

    it "sends GET request to resource endpoint" do
      TestResource.retrieve("test_123")

      expect(WebMock).to have_requested(:get, "https://api-demo.airwallex.com/api/v1/test_resources/test_123")
    end

    it "returns instance of calling class" do
      resource = TestResource.retrieve("test_123")

      expect(resource.class).to eq(TestResource)
    end
  end
end
