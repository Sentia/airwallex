# frozen_string_literal: true

require "spec_helper"

RSpec.describe Airwallex::APIOperations::List do
  let(:test_class) do
    Class.new(Airwallex::APIResource) do
      extend Airwallex::APIOperations::List

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

  describe ".list" do
    let(:list_response) do
      {
        items: [
          { id: "test_1", name: "Item 1", value: 100 },
          { id: "test_2", name: "Item 2", value: 200 }
        ],
        has_more: false
      }
    end

    before do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/test_resources")
        .with(query: { page_size: 10 })
        .to_return(
          status: 200,
          body: list_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "lists resources" do
      list = TestResource.list(page_size: 10)

      expect(list).to be_a(Airwallex::ListObject)
      expect(list.size).to eq(2)
    end

    it "returns ListObject with correct resource class" do
      list = TestResource.list(page_size: 10)

      expect(list.data).to all(be_a(TestResource))
      expect(list.first.id).to eq("test_1")
      expect(list.last.id).to eq("test_2")
    end

    it "sends GET request with query params" do
      TestResource.list(page_size: 10)

      expect(WebMock).to have_requested(:get, "https://api-demo.airwallex.com/api/v1/test_resources")
        .with(query: { page_size: 10 })
    end

    it "passes filters to API" do
      stub_request(:get, "https://api-demo.airwallex.com/api/v1/test_resources")
        .with(query: { page_size: 20, status: "active" })
        .to_return(
          status: 200,
          body: list_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      TestResource.list(page_size: 20, status: "active")

      expect(WebMock).to have_requested(:get, "https://api-demo.airwallex.com/api/v1/test_resources")
        .with(query: { page_size: 20, status: "active" })
    end
  end
end
