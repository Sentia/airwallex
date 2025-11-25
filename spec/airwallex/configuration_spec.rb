# frozen_string_literal: true

RSpec.describe Airwallex::Configuration do
  subject(:config) { described_class.new }

  describe "#initialize" do
    it "sets default environment to sandbox" do
      expect(config.environment).to eq(:sandbox)
    end

    it "sets default API version" do
      expect(config.api_version).to eq("2024-09-27")
    end

    it "sets default log level" do
      expect(config.log_level).to eq(:info)
    end
  end

  describe "#environment=" do
    it "accepts :sandbox" do
      config.environment = :sandbox
      expect(config.environment).to eq(:sandbox)
    end

    it "accepts :production" do
      config.environment = :production
      expect(config.environment).to eq(:production)
    end

    it "raises error for invalid environment" do
      expect { config.environment = :invalid }.to raise_error(
        Airwallex::ConfigurationError,
        /Invalid environment/
      )
    end
  end

  describe "#api_url" do
    context "when environment is sandbox" do
      before { config.environment = :sandbox }

      it "returns the sandbox API URL" do
        expect(config.api_url).to eq("https://api-demo.airwallex.com")
      end
    end

    context "when environment is production" do
      before { config.environment = :production }

      it "returns production API URL" do
        expect(config.api_url).to eq("https://api.airwallex.com")
      end
    end
  end

  describe "#files_url" do
    context "when environment is sandbox" do
      before { config.environment = :sandbox }

      it "returns sandbox files URL" do
        expect(config.files_url).to eq("https://files-demo.airwallex.com")
      end
    end

    context "when environment is production" do
      before { config.environment = :production }

      it "returns production files URL" do
        expect(config.files_url).to eq("https://files.airwallex.com")
      end
    end
  end

  describe "#validate!" do
    it "raises error when api_key is missing" do
      config.client_id = "test_id"
      expect { config.validate! }.to raise_error(
        Airwallex::ConfigurationError,
        /api_key is required/
      )
    end

    it "raises error when client_id is missing" do
      config.api_key = "test_key"
      expect { config.validate! }.to raise_error(
        Airwallex::ConfigurationError,
        /client_id is required/
      )
    end

    it "raises error when both are missing" do
      expect { config.validate! }.to raise_error(
        Airwallex::ConfigurationError,
        /api_key is required.*client_id is required/
      )
    end

    it "returns true when all required fields are present" do
      config.api_key = "test_key"
      config.client_id = "test_id"
      expect(config.validate!).to be true
    end
  end

  describe "#configured?" do
    it "returns false when api_key is missing" do
      config.client_id = "test_id"
      expect(config.configured?).to be false
    end

    it "returns false when client_id is missing" do
      config.api_key = "test_key"
      expect(config.configured?).to be false
    end

    it "returns true when all required fields are present" do
      config.api_key = "test_key"
      config.client_id = "test_id"
      expect(config.configured?).to be true
    end
  end
end
