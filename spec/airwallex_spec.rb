# frozen_string_literal: true

RSpec.describe Airwallex do
  it "has a version number" do
    expect(Airwallex::VERSION).not_to be nil
  end

  it "can be configured" do
    Airwallex.configure do |config|
      config.api_key = "test_key"
      config.client_id = "test_id"
    end

    expect(Airwallex.configuration.api_key).to eq("test_key")
    expect(Airwallex.configuration.client_id).to eq("test_id")
  end
end
