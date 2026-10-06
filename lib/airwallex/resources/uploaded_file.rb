# frozen_string_literal: true

module Airwallex
  # Represents a file uploaded to Airwallex's files host (config.files_url,
  # not the main API host) — e.g. a KYC document. The returned file_id is
  # what other endpoints reference, such as RFI answers
  # (attachments[].file_id, identity_document front_file_id/back_file_id).
  # See https://www.airwallex.com/docs/api/supporting_services/file_service/upload_files
  #
  # Limits: 20MB per file; filename and notes up to 50 characters each.
  # The response has file_id, filename, notes, size (bytes), object_type
  # and created (epoch seconds, not created_at).
  #
  # Named UploadedFile rather than File so that bare File.open/File.read
  # inside the Airwallex module still resolve to ::File.
  #
  # @example Upload a PDF on behalf of a connected account
  #   file = Airwallex::UploadedFile.upload(
  #     File.open("smo_declaration.pdf", "rb"),
  #     filename: "smo_declaration.pdf",
  #     content_type: "application/pdf",
  #     notes: "SMO declaration",
  #     opts: { headers: { "x-on-behalf-of" => "acct_123" } }
  #   )
  #   file.file_id # => "..."
  class UploadedFile < APIResource
    # @return [String] API path for file uploads, on the files host
    def self.resource_path
      "/api/v1/files/upload"
    end

    # Upload a file as multipart/form-data (form field "file")
    #
    # @param io [IO, StringIO, String] an IO, or a local file path
    # @param filename [String]
    # @param content_type [String] e.g. "application/pdf", "image/jpeg"
    # @param notes [String, nil] a label, sent as the notes form field
    # @param opts [Hash] headers: (e.g. { "x-on-behalf-of" => account_id })
    # @return [UploadedFile]
    def self.upload(io, filename:, content_type:, notes: nil, opts: {})
      file_part = Faraday::Multipart::FilePart.new(io, content_type, filename)
      params = notes.nil? ? {} : { notes: notes }
      response = Airwallex.client.upload(resource_path, file_part, params, opts[:headers] || {})
      new(response)
    end

    # The upload response identifies the file by file_id, not id, so id
    # mirrors file_id to behave like other resources
    def initialize(attributes = {})
      super
      @id ||= @attributes[:file_id]
    end

    def refresh_from(data)
      super
      @id ||= @attributes[:file_id]
      self
    end

    # @return [String, nil]
    def file_id
      @attributes[:file_id]
    end
  end
end
