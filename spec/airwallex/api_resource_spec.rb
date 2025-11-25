# frozen_string_literal: true

require "spec_helper"

RSpec.describe Airwallex::APIResource do
  let(:test_class) do
    Class.new(Airwallex::APIResource) do
      def self.name
        "Airwallex::TestResource"
      end

      def self.resource_path
        "/api/v1/test_resources"
      end
    end
  end

  let(:attributes) do
    {
      id: "test_123",
      name: "Test Resource",
      amount: 100,
      nested: {
        field: "value"
      }
    }
  end

  describe "#initialize" do
    it "creates resource with attributes" do
      resource = test_class.new(attributes)
      expect(resource.id).to eq("test_123")
      expect(resource.attributes[:id]).to eq("test_123")
    end

    it "symbolizes attribute keys" do
      resource = test_class.new("id" => "test_123", "name" => "Test")
      expect(resource.attributes.keys).to all(be_a(Symbol))
    end

    it "handles nil attributes" do
      resource = test_class.new(nil)
      expect(resource.attributes).to eq({})
      expect(resource.id).to be_nil
    end
  end

  describe ".resource_name" do
    it "converts class name to snake_case" do
      expect(test_class.resource_name).to eq("test_resource")
    end

    it "handles multi-word names" do
      klass = Class.new(Airwallex::APIResource) do
        def self.name
          "Airwallex::PaymentIntent"
        end
      end
      expect(klass.resource_name).to eq("payment_intent")
    end
  end

  describe ".resource_path" do
    it "returns resource path" do
      expect(test_class.resource_path).to eq("/api/v1/test_resources")
    end

    it "raises NotImplementedError if not overridden" do
      klass = Class.new(Airwallex::APIResource)
      expect { klass.resource_path }.to raise_error(NotImplementedError)
    end
  end

  describe "dynamic attribute access" do
    let(:resource) { test_class.new(attributes) }

    it "allows getter access" do
      expect(resource.name).to eq("Test Resource")
      expect(resource.amount).to eq(100)
    end

    it "allows setter access" do
      resource.name = "New Name"
      expect(resource.name).to eq("New Name")
      expect(resource.attributes[:name]).to eq("New Name")
    end

    it "responds to attribute methods" do
      expect(resource.respond_to?(:name)).to be true
      expect(resource.respond_to?(:name=)).to be true
    end

    it "raises NoMethodError for non-existent attributes" do
      expect { resource.nonexistent }.to raise_error(NoMethodError)
    end

    it "accesses nested attributes" do
      expect(resource.nested).to eq({ field: "value" })
    end
  end

  describe "dirty tracking" do
    let(:resource) { test_class.new(attributes) }

    it "tracks changed attributes" do
      expect(resource.dirty?).to be false

      resource.name = "New Name"
      expect(resource.dirty?).to be true
      expect(resource.changed_attributes).to include(:name)
    end

    it "stores previous values" do
      original_name = resource.name
      resource.name = "New Name"

      expect(resource.instance_variable_get(:@previous_attributes)[:name]).to eq(original_name)
    end

    it "tracks multiple changes" do
      resource.name = "New Name"
      resource.amount = 200

      expect(resource.changed_attributes).to contain_exactly(:name, :amount)
    end
  end

  describe "#refresh" do
    let(:resource) { test_class.new(attributes) }

    before do
      stub_request(:post, "https://api-demo.airwallex.com/api/v1/authentication/login")
        .to_return(
          status: 200,
          body: { token: "test_token" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      stub_request(:get, "https://api-demo.airwallex.com/api/v1/test_resources/test_123")
        .to_return(
          status: 200,
          body: { id: "test_123", name: "Updated Name", amount: 200 }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "fetches latest data from API" do
      resource.refresh

      expect(resource.name).to eq("Updated Name")
      expect(resource.amount).to eq(200)
    end

    it "returns self" do
      expect(resource.refresh).to eq(resource)
    end

    it "clears dirty tracking" do
      resource.name = "Modified"
      expect(resource.dirty?).to be true

      resource.refresh
      expect(resource.dirty?).to be false
    end
  end

  describe "#refresh_from" do
    let(:resource) { test_class.new(attributes) }
    let(:new_data) { { id: "test_123", name: "New Name", amount: 500 } }

    it "updates attributes from data" do
      resource.refresh_from(new_data)

      expect(resource.name).to eq("New Name")
      expect(resource.amount).to eq(500)
    end

    it "symbolizes keys" do
      resource.refresh_from("id" => "test_123", "name" => "New")
      expect(resource.attributes.keys).to all(be_a(Symbol))
    end

    it "clears dirty tracking" do
      resource.name = "Modified"
      resource.refresh_from(new_data)

      expect(resource.dirty?).to be false
    end

    it "returns self" do
      expect(resource.refresh_from(new_data)).to eq(resource)
    end
  end

  describe "#to_hash" do
    let(:resource) { test_class.new(attributes) }

    it "returns attributes as hash" do
      expect(resource.to_hash).to eq(attributes)
    end

    it "returns a copy" do
      hash = resource.to_hash
      hash[:name] = "Modified"

      expect(resource.name).to eq("Test Resource")
    end
  end

  describe "#to_json" do
    let(:resource) { test_class.new(attributes) }

    it "returns JSON string" do
      json = resource.to_json
      expect(json).to be_a(String)

      parsed = JSON.parse(json, symbolize_names: true)
      expect(parsed[:id]).to eq("test_123")
    end
  end

  describe "#inspect" do
    it "includes class name and id" do
      resource = test_class.new(id: "test_123")
      expect(resource.inspect).to include("test_123")
      expect(resource.inspect).to include("JSON")
    end

    it "works without id" do
      resource = test_class.new(name: "Test")
      expect(resource.inspect).to include("JSON")
      expect(resource.inspect).to include("Test")
    end
  end
end
