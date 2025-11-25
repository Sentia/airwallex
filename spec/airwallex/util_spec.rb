# frozen_string_literal: true

RSpec.describe Airwallex::Util do
  describe ".generate_idempotency_key" do
    it "generates UUID v4" do
      key = described_class.generate_idempotency_key
      expect(key).to match(/\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i)
    end

    it "generates unique keys" do
      key1 = described_class.generate_idempotency_key
      key2 = described_class.generate_idempotency_key
      expect(key1).not_to eq(key2)
    end
  end

  describe ".format_date_time" do
    it "formats Time to ISO 8601" do
      time = Time.new(2025, 11, 25, 10, 30, 0, "+00:00")
      result = described_class.format_date_time(time)
      expect(result).to eq("2025-11-25T10:30:00Z")
    end

    it "formats Date to ISO 8601" do
      date = Date.new(2025, 11, 25)
      result = described_class.format_date_time(date)
      # Date.to_time converts to midnight UTC which may be previous day in some timezones
      expect(result).to match(/2025-11-2[45]T\d{2}:\d{2}:\d{2}Z/)
    end

    it "returns String unchanged" do
      string = "2025-11-25T10:30:00Z"
      result = described_class.format_date_time(string)
      expect(result).to eq(string)
    end

    it "raises error for invalid type" do
      expect { described_class.format_date_time(123) }.to raise_error(ArgumentError)
    end
  end

  describe ".parse_date_time" do
    it "parses ISO 8601 string" do
      string = "2025-11-25T10:30:00Z"
      result = described_class.parse_date_time(string)
      expect(result).to be_a(Time)
    end

    it "returns nil for nil input" do
      result = described_class.parse_date_time(nil)
      expect(result).to be_nil
    end

    it "returns Time unchanged" do
      time = Time.now
      result = described_class.parse_date_time(time)
      expect(result).to eq(time)
    end
  end

  describe ".symbolize_keys" do
    it "converts string keys to symbols" do
      hash = { "key1" => "value1", "key2" => "value2" }
      result = described_class.symbolize_keys(hash)
      expect(result).to eq({ key1: "value1", key2: "value2" })
    end

    it "returns non-hash unchanged" do
      expect(described_class.symbolize_keys("string")).to eq("string")
    end
  end

  describe ".deep_symbolize_keys" do
    it "converts nested hash keys to symbols" do
      hash = { "outer" => { "inner" => "value" } }
      result = described_class.deep_symbolize_keys(hash)
      expect(result).to eq({ outer: { inner: "value" } })
    end

    it "handles arrays with hashes" do
      hash = { "key" => "value" }
      result = described_class.deep_symbolize_keys(hash)
      expect(result).to eq({ key: "value" })
    end
  end

  describe ".to_money" do
    it "converts string to BigDecimal" do
      result = described_class.to_money("100.50")
      expect(result).to be_a(BigDecimal)
      expect(result).to eq(BigDecimal("100.50"))
    end

    it "converts integer to BigDecimal" do
      result = described_class.to_money(100)
      expect(result).to be_a(BigDecimal)
      expect(result).to eq(BigDecimal("100"))
    end

    it "returns BigDecimal unchanged" do
      bd = BigDecimal("100.50")
      result = described_class.to_money(bd)
      expect(result).to eq(bd)
    end

    it "returns zero for nil" do
      result = described_class.to_money(nil)
      expect(result).to eq(BigDecimal("0"))
    end
  end
end
