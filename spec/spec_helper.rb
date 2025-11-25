# frozen_string_literal: true

require "airwallex"
require "webmock/rspec"

# Configure WebMock to block all real HTTP requests
WebMock.disable_net_connect!(allow_localhost: false)

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Reset Airwallex configuration before each test
  config.before do
    Airwallex.reset!
    Airwallex.configure do |c|
      c.api_key = "test_api_key"
      c.client_id = "test_client_id"
      c.environment = :sandbox
    end
  end

  # Clean up after each test
  config.after do
    Airwallex.reset!
  end
end
