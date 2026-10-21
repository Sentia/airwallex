# frozen_string_literal: true

require "spec_helper"

RSpec.describe Airwallex::EmbeddedComponent do
  let(:authorize_url) { "#{BASE_URL}/api/v1/authentication/authorize" }
  let(:on_behalf_of) { { "x-on-behalf-of" => "acct_123" } }
  let(:code_challenge) { "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM" }

  def json_response(body, status: 200)
    { status: status, body: body.to_json, headers: { "Content-Type" => "application/json" } }
  end

  describe ".authorize" do
    it "posts the code challenge and scope with x-on-behalf-of and returns a symbolized Hash" do
      stub = stub_request(:post, authorize_url)
             .with(body: { code_challenge: code_challenge, scope: ["transfer:write"] }.to_json,
                   headers: on_behalf_of.merge("Content-Type" => "application/json"))
             .to_return(json_response({ authorization_code: "ac_123" }))

      result = described_class.authorize(code_challenge: code_challenge, scope: ["transfer:write"],
                                         headers: on_behalf_of)

      expect(stub).to have_been_requested
      expect(result).to eq(authorization_code: "ac_123")
    end

    it "sends identity when given" do
      stub = stub_request(:post, authorize_url)
             .with(body: { code_challenge: code_challenge, scope: ["sca:write"], identity: "user_123" }.to_json)
             .to_return(json_response({ authorization_code: "ac_123" }))

      described_class.authorize(code_challenge: code_challenge, scope: ["sca:write"], identity: "user_123")

      expect(stub).to have_been_requested
    end

    it "does not add a request_id or x-on-behalf-of by default" do
      stub = stub_request(:post, authorize_url)
             .with { |req| !JSON.parse(req.body).key?("request_id") && !req.headers.key?("X-On-Behalf-Of") }
             .to_return(json_response({ authorization_code: "ac_123" }))

      described_class.authorize(code_challenge: code_challenge, scope: ["transfer:write"])

      expect(stub).to have_been_requested
    end

    it "raises BadRequestError for an invalid scope" do
      stub_request(:post, authorize_url)
        .to_return(json_response({ code: "invalid_argument", message: "invalid scope" }, status: 400))

      expect { described_class.authorize(code_challenge: code_challenge, scope: ["nope"]) }
        .to raise_error(Airwallex::BadRequestError, /invalid scope/) { |e| expect(e.code).to eq("invalid_argument") }
    end
  end
end
