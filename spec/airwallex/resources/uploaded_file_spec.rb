# frozen_string_literal: true

require "spec_helper"

RSpec.describe Airwallex::UploadedFile do
  let(:files_url) { Airwallex::Configuration::SANDBOX_FILES_URL }
  let(:on_behalf_of) { { "x-on-behalf-of" => "acct_123" } }
  let(:io) { StringIO.new("%PDF-1.4 fake pdf bytes") }

  def json_response(body)
    { status: 200, body: body.to_json, headers: { "Content-Type" => "application/json" } }
  end

  def upload(**kwargs)
    described_class.upload(io, filename: "smo.pdf", content_type: "application/pdf", **kwargs)
  end

  describe ".upload" do
    it "posts multipart to the sandbox files host and returns the file_id" do
      stub = stub_request(:post, "#{files_url}/api/v1/files/upload")
             .with(headers: { "Authorization" => "Bearer test_token" }) do |req|
               req.headers["Content-Type"].start_with?("multipart/form-data; boundary=") &&
                 req.body.include?('Content-Disposition: form-data; name="file"; filename="smo.pdf"') &&
                 req.body.include?("Content-Type: application/pdf") &&
                 req.body.include?("%PDF-1.4 fake pdf bytes")
             end
             .to_return(json_response(file_id: "file_123", filename: "smo.pdf", size: 23, created: 1_791_244_800))

      file = upload

      expect(stub).to have_been_requested
      expect(file).to be_a(described_class)
      expect(file.file_id).to eq("file_123")
      expect(file.id).to eq("file_123")
      expect(file.size).to eq(23)
    end

    it "does not hit the main API host" do
      stub_request(:post, "#{files_url}/api/v1/files/upload").to_return(json_response(file_id: "file_123"))

      upload

      expect(a_request(:post, "#{BASE_URL}/api/v1/files/upload")).not_to have_been_made
    end

    it "uses the production files host in production" do
      Airwallex.configure { |c| c.environment = :production }
      stub_request(:post, "#{Airwallex::Configuration::PRODUCTION_API_URL}#{LOGIN_PATH}")
        .to_return(json_response(token: "prod_token"))
      stub = stub_request(:post, "#{Airwallex::Configuration::PRODUCTION_FILES_URL}/api/v1/files/upload")
             .with(headers: { "Authorization" => "Bearer prod_token" })
             .to_return(json_response(file_id: "file_prod"))

      expect(upload.file_id).to eq("file_prod")
      expect(stub).to have_been_requested
    end

    it "sends notes as a form field and passes x-on-behalf-of" do
      stub = stub_request(:post, "#{files_url}/api/v1/files/upload")
             .with(headers: on_behalf_of) do |req|
               req.body.include?(%(Content-Disposition: form-data; name="notes"\r\n\r\nSMO declaration))
             end
             .to_return(json_response(file_id: "file_123"))

      upload(notes: "SMO declaration", opts: { headers: on_behalf_of })

      expect(stub).to have_been_requested
    end

    it "sends only the file part, with no request_id" do
      stub = stub_request(:post, "#{files_url}/api/v1/files/upload")
             .with { |req| req.body.scan("Content-Disposition: form-data").size == 1 && !req.body.include?("request_id") }
             .to_return(json_response(file_id: "file_123"))

      upload

      expect(stub).to have_been_requested
    end

    it "re-sends the file after refreshing an expired token" do
      bodies = []
      stub_request(:post, "#{files_url}/api/v1/files/upload")
        .with { |req| bodies << req.body }
        .to_return({ status: 401, body: { code: "unauthorized" }.to_json,
                     headers: { "Content-Type" => "application/json" } },
                   json_response(file_id: "file_123"))

      expect(upload.file_id).to eq("file_123")
      expect(bodies.size).to eq(2)
      expect(bodies.last).to include("%PDF-1.4 fake pdf bytes")
    end

    it "raises the gem's error classes" do
      stub_request(:post, "#{files_url}/api/v1/files/upload")
        .to_return(status: 400, body: { code: "invalid_argument", message: "bad file" }.to_json,
                   headers: { "Content-Type" => "application/json" })

      expect { upload }.to raise_error(Airwallex::BadRequestError, /bad file/)
    end
  end
end
