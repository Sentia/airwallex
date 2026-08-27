# frozen_string_literal: true

# Central source for the sandbox host and login path, instead of repeating
# the literal strings in every spec file. Defined at the top level (not
# inside a module) so they resolve unqualified from any spec file: constant
# lookup is lexical, so a constant nested in a module included via
# `config.include` would NOT be visible here the way an included method is.
BASE_URL = Airwallex::Configuration::SANDBOX_API_URL
LOGIN_PATH = Airwallex::Client::LOGIN_PATH

# Shared stubs for hitting the sandbox API across specs.
module AirwallexTestHelpers
  def stub_login(status: 200, token: "test_token")
    stub_request(:post, "#{BASE_URL}#{LOGIN_PATH}")
      .to_return(
        status: status,
        body: { token: token }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end
end
