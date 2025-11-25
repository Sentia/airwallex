# frozen_string_literal: true

require "spec_helper"

RSpec.describe Airwallex::APIOperations::Update do
  let(:test_class) do
    Class.new(Airwallex::APIResource) do
      extend Airwallex::APIOperations::Update
      include Airwallex::APIOperations::Update

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

  describe ".update" do
    let(:update_params) do
      {
        name: "Updated Name",
        value: 200
      }
    end

    let(:update_response) do
      {
        id: "test_123",
        name: "Updated Name",
        value: 200
      }
    end

    before do
      stub_request(:put, "https://api-demo.airwallex.com/api/v1/test_resources/test_123")
        .with(body: hash_including(update_params))
        .to_return(
          status: 200,
          body: update_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "updates resource by id" do
      resource = TestResource.update("test_123", update_params)

      expect(resource).to be_a(TestResource)
      expect(resource.id).to eq("test_123")
      expect(resource.name).to eq("Updated Name")
      expect(resource.value).to eq(200)
    end

    it "sends PUT request with params" do
      TestResource.update("test_123", update_params)

      expect(WebMock).to have_requested(:put, "https://api-demo.airwallex.com/api/v1/test_resources/test_123")
        .with(body: hash_including(update_params))
    end
  end

  describe "#update" do
    let(:resource) do
      TestResource.new(
        id: "test_123",
        name: "Original Name",
        value: 100
      )
    end

    let(:update_response) do
      {
        id: "test_123",
        name: "Updated Name",
        value: 100
      }
    end

    before do
      stub_request(:put, "https://api-demo.airwallex.com/api/v1/test_resources/test_123")
        .to_return(
          status: 200,
          body: update_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "updates instance with params" do
      result = resource.update(name: "Updated Name")

      expect(result).to eq(resource)
      expect(resource.name).to eq("Updated Name")
    end

    it "returns self" do
      result = resource.update(name: "Updated Name")

      expect(result).to be(resource)
    end
  end

  describe "#save" do
    let(:resource) do
      TestResource.new(
        id: "test_123",
        name: "Original Name",
        value: 100
      )
    end

    let(:update_response) do
      {
        id: "test_123",
        name: "Updated Name",
        value: 200
      }
    end

    context "when attributes changed" do
      before do
        stub_request(:put, "https://api-demo.airwallex.com/api/v1/test_resources/test_123")
          .to_return(
            status: 200,
            body: update_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "saves changed attributes" do
        resource.name = "Updated Name"
        resource.value = 200
        resource.save

        expect(resource.name).to eq("Updated Name")
        expect(resource.value).to eq(200)
      end

      it "sends only changed attributes" do
        resource.name = "Updated Name"
        resource.save

        expect(WebMock).to have_requested(:put, "https://api-demo.airwallex.com/api/v1/test_resources/test_123")
          .with(body: hash_including(name: "Updated Name"))
      end

      it "returns self" do
        resource.name = "Updated Name"
        result = resource.save

        expect(result).to be(resource)
      end
    end

    context "when no attributes changed" do
      it "does not make API call" do
        resource.save

        expect(WebMock).not_to have_requested(:put, /test_resources/)
      end

      it "returns self" do
        result = resource.save

        expect(result).to be(resource)
      end
    end
  end
end
