# frozen_string_literal: true

RSpec.describe Airwallex::Webhook do
  let(:secret) { "test_secret" }
  let(:payload) { '{"id":"evt_123","type":"payment_intent.succeeded","data":{}}' }
  let(:timestamp) { Time.now.to_i.to_s }
  let(:signature) { described_class.send(:compute_signature, timestamp, payload, secret) }

  describe ".construct_event" do
    it "constructs event with valid signature" do
      event = described_class.construct_event(payload, signature, timestamp, secret: secret)
      expect(event).to be_a(Airwallex::Webhook::Event)
    end

    it "raises error with invalid signature" do
      expect do
        described_class.construct_event(payload, "invalid_sig", timestamp, secret: secret)
      end.to raise_error(Airwallex::SignatureVerificationError, /Signature verification failed/)
    end

    it "raises error with old timestamp" do
      old_timestamp = (Time.now.to_i - 400).to_s
      old_signature = described_class.send(:compute_signature, old_timestamp, payload, secret)

      expect do
        described_class.construct_event(payload, old_signature, old_timestamp, secret: secret)
      end.to raise_error(Airwallex::SignatureVerificationError, /Timestamp outside tolerance/)
    end

    it "accepts custom tolerance" do
      old_timestamp = (Time.now.to_i - 400).to_s
      old_signature = described_class.send(:compute_signature, old_timestamp, payload, secret)

      event = described_class.construct_event(
        payload, old_signature, old_timestamp,
        secret: secret, tolerance: 600
      )
      expect(event).to be_a(Airwallex::Webhook::Event)
    end

    it "raises error with invalid JSON" do
      invalid_payload = "not json"
      invalid_signature = described_class.send(:compute_signature, timestamp, invalid_payload, secret)

      expect do
        described_class.construct_event(invalid_payload, invalid_signature, timestamp, secret: secret)
      end.to raise_error(Airwallex::SignatureVerificationError, /Invalid payload/)
    end
  end

  describe ".verify_signature" do
    it "returns true for valid signature" do
      result = described_class.verify_signature(payload, signature, timestamp, secret, 300)
      expect(result).to be true
    end

    it "raises error for invalid signature" do
      expect do
        described_class.verify_signature(payload, "invalid", timestamp, secret, 300)
      end.to raise_error(Airwallex::SignatureVerificationError)
    end
  end

  describe "Event" do
    let(:event_data) do
      {
        "id" => "evt_123",
        "type" => "payment_intent.succeeded",
        "data" => { "amount" => 100 },
        "created_at" => "2025-11-25T10:00:00Z"
      }
    end

    subject(:event) { Airwallex::Webhook::Event.new(event_data) }

    it "has id" do
      expect(event.id).to eq("evt_123")
    end

    it "has type" do
      expect(event.type).to eq("payment_intent.succeeded")
    end

    it "has data" do
      expect(event.data).to eq({ "amount" => 100 })
    end

    it "has created_at" do
      expect(event.created_at).to eq("2025-11-25T10:00:00Z")
    end
  end
end
