# frozen_string_literal: true

require "spec_helper"

RSpec.describe Airwallex::APIOperations::Delete do
  let(:test_class) do
    Class.new(Airwallex::APIResource) do
      extend Airwallex::APIOperations::Delete

      def self.resource_path
        "/api/v1/test_resources"
      end
    end
  end

  before do
    stub_const("TestResource", test_class)
  end

  describe ".delete" do
    before do
      stub_request(:post, "#{BASE_URL}/api/v1/test_resources/test_123/delete")
        .to_return(
          status: 200,
          body: "true",
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "deletes resource by id" do
      result = TestResource.delete("test_123")

      expect(result).to be true
    end

    it "sends POST request to the delete endpoint" do
      TestResource.delete("test_123")

      expect(WebMock).to have_requested(:post, "#{BASE_URL}/api/v1/test_resources/test_123/delete")
    end

    it "returns false when deletion did not take place" do
      stub_request(:post, "#{BASE_URL}/api/v1/test_resources/test_456/delete")
        .to_return(
          status: 200,
          body: "false",
          headers: { "Content-Type" => "application/json" }
        )

      result = TestResource.delete("test_456")

      expect(result).to be false
    end
  end
end
