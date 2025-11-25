# frozen_string_literal: true

require "spec_helper"

RSpec.describe Airwallex::ListObject do
  let(:resource_class) do
    Class.new(Airwallex::APIResource) do
      extend Airwallex::APIOperations::List

      def self.name
        "Airwallex::TestResource"
      end

      def self.resource_path
        "/api/v1/test_resources"
      end
    end
  end

  let(:items_data) do
    [
      { id: "item_1", name: "Item 1" },
      { id: "item_2", name: "Item 2" },
      { id: "item_3", name: "Item 3" }
    ]
  end

  describe "#initialize" do
    it "wraps items as resource instances" do
      list = described_class.new(
        data: items_data,
        has_more: false,
        resource_class: resource_class
      )

      expect(list.data).to all(be_a(resource_class))
      expect(list.data.size).to eq(3)
    end

    it "stores pagination metadata" do
      list = described_class.new(
        data: items_data,
        has_more: true,
        next_cursor: "cursor_123",
        resource_class: resource_class
      )

      expect(list.has_more).to be true
      expect(list.next_cursor).to eq("cursor_123")
    end
  end

  describe "Enumerable interface" do
    let(:list) do
      described_class.new(
        data: items_data,
        has_more: false,
        resource_class: resource_class
      )
    end

    it "implements #each" do
      expect(list).to respond_to(:each)

      names = []
      list.each { |item| names << item.name }
      expect(names).to eq(["Item 1", "Item 2", "Item 3"])
    end

    it "supports map" do
      ids = list.map(&:id)
      expect(ids).to eq(["item_1", "item_2", "item_3"])
    end

    it "supports select" do
      filtered = list.select { |item| item.id == "item_2" }
      expect(filtered.size).to eq(1)
      expect(filtered.first.id).to eq("item_2")
    end

    it "supports first" do
      expect(list.first.id).to eq("item_1")
    end

    it "supports last" do
      expect(list.last.id).to eq("item_3")
    end
  end

  describe "#[]" do
    let(:list) do
      described_class.new(
        data: items_data,
        has_more: false,
        resource_class: resource_class
      )
    end

    it "accesses items by index" do
      expect(list[0].id).to eq("item_1")
      expect(list[1].id).to eq("item_2")
      expect(list[2].id).to eq("item_3")
    end

    it "returns nil for out of bounds" do
      expect(list[10]).to be_nil
    end
  end

  describe "#size" do
    it "returns number of items" do
      list = described_class.new(
        data: items_data,
        has_more: false,
        resource_class: resource_class
      )

      expect(list.size).to eq(3)
      expect(list.length).to eq(3)
      expect(list.count).to eq(3)
    end
  end

  describe "#empty?" do
    it "returns true when no items" do
      list = described_class.new(
        data: [],
        has_more: false,
        resource_class: resource_class
      )

      expect(list.empty?).to be true
    end

    it "returns false when has items" do
      list = described_class.new(
        data: items_data,
        has_more: false,
        resource_class: resource_class
      )

      expect(list.empty?).to be false
    end
  end

  describe "#next_page" do
    before do
      stub_request(:post, "https://api-demo.airwallex.com/api/v1/authentication/login")
        .to_return(
          status: 200,
          body: { token: "test_token" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    context "with cursor pagination" do
      it "fetches next page using cursor" do
        stub_request(:get, "https://api-demo.airwallex.com/api/v1/test_resources")
          .with(query: { next_cursor: "cursor_123", page_size: 10 })
          .to_return(
            status: 200,
            body: {
              items: [{ id: "item_4", name: "Item 4" }],
              has_more: false
            }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        list = described_class.new(
          data: items_data,
          has_more: true,
          next_cursor: "cursor_123",
          resource_class: resource_class,
          params: { page_size: 10 }
        )

        allow(resource_class).to receive(:list).and_call_original

        next_page = list.next_page

        expect(resource_class).to have_received(:list).with(
          hash_including(next_cursor: "cursor_123")
        )
      end
    end

    context "with offset pagination" do
      it "fetches next page using offset" do
        stub_request(:get, "https://api-demo.airwallex.com/api/v1/test_resources")
          .with(query: { offset: 20, page_size: 20 })
          .to_return(
            status: 200,
            body: {
              items: [{ id: "item_21", name: "Item 21" }],
              has_more: false
            }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        list = described_class.new(
          data: items_data,
          has_more: true,
          resource_class: resource_class,
          params: { offset: 0, page_size: 20 }
        )

        allow(resource_class).to receive(:list).and_call_original

        next_page = list.next_page

        expect(resource_class).to have_received(:list).with(
          hash_including(offset: 20)
        )
      end
    end

    it "returns nil when no more pages" do
      list = described_class.new(
        data: items_data,
        has_more: false,
        resource_class: resource_class
      )

      expect(list.next_page).to be_nil
    end
  end

  describe "#auto_paging_each" do
    before do
      stub_request(:post, "https://api-demo.airwallex.com/api/v1/authentication/login")
        .to_return(
          status: 200,
          body: { token: "test_token" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      stub_request(:get, "https://api-demo.airwallex.com/api/v1/test_resources")
        .with(query: { page_size: 2 })
        .to_return(
          status: 200,
          body: {
            items: [{ id: "item_1" }, { id: "item_2" }],
            has_more: true,
            next_cursor: "cursor_1"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      stub_request(:get, "https://api-demo.airwallex.com/api/v1/test_resources")
        .with(query: { page_size: 2, next_cursor: "cursor_1" })
        .to_return(
          status: 200,
          body: {
            items: [{ id: "item_3" }, { id: "item_4" }],
            has_more: false
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "iterates through all pages automatically" do
      list = described_class.new(
        data: [{ id: "item_1" }, { id: "item_2" }],
        has_more: true,
        next_cursor: "cursor_1",
        resource_class: resource_class,
        params: { page_size: 2 }
      )

      allow(resource_class).to receive(:list).and_call_original

      ids = []
      list.auto_paging_each { |item| ids << item.id }

      expect(ids).to include("item_1", "item_2", "item_3", "item_4")
    end

    it "returns enumerator without block" do
      list = described_class.new(
        data: items_data,
        has_more: false,
        resource_class: resource_class
      )

      enumerator = list.auto_paging_each
      expect(enumerator).to be_a(Enumerator)
    end
  end

  describe "#to_a" do
    it "returns array of resources" do
      list = described_class.new(
        data: items_data,
        has_more: false,
        resource_class: resource_class
      )

      array = list.to_a
      expect(array).to be_a(Array)
      expect(array.size).to eq(3)
      expect(array).to all(be_a(resource_class))
    end
  end

  describe "#inspect" do
    it "shows size and has_more status" do
      list = described_class.new(
        data: items_data,
        has_more: true,
        resource_class: resource_class
      )

      inspection = list.inspect
      expect(inspection).to include("ListObject")
      expect(inspection).to include("[3]")
      expect(inspection).to include("has_more=true")
    end
  end
end
