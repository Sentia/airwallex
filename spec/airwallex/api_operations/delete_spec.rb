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
      stub_request(:delete, "#{BASE_URL}/api/v1/test_resources/test_123")
        .to_return(
          status: 200,
          body: {}.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "deletes resource by id" do
      result = TestResource.delete("test_123")

      expect(result).to be true
    end

    it "sends DELETE request" do
      TestResource.delete("test_123")

      expect(WebMock).to have_requested(:delete, "#{BASE_URL}/api/v1/test_resources/test_123")
    end
  end
end
