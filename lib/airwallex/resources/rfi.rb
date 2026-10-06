# frozen_string_literal: true

module Airwallex
  # Represents a Request for Information (RFI) — a compliance question
  # Airwallex raises against your account (KYC, an ongoing KYC review, a
  # cardholder, a transaction, payment enablement, or merchant risk).
  #
  # Supports retrieving, listing and responding to real RFIs, plus the sandbox Simulation
  # endpoints for raising, closing and following up on them (there is no
  # live create — real RFIs originate from Airwallex's own compliance
  # review, same as Dispute). See
  # https://www.airwallex.com/docs/api/risk/request_for_information_rfi and
  # https://www.airwallex.com/docs/api/simulation/request-for-information
  #
  # Statuses: ACTION_REQUIRED, ANSWERED, CLOSED. Types: KYC, KYC_ONGOING,
  # CARDHOLDER, TRANSACTION, PAYMENT_ENABLEMENT, MERCHANT_RISK.
  #
  # Reading RFIs requires the API key's "Risk → Request for Information
  # (RFI): Read" permission — without it Airwallex returns 401
  # (AuthenticationError).
  #
  # @example Retrieve an RFI for a connected account
  #   rfi = Airwallex::RFI.retrieve("rfi_123", headers: { "x-on-behalf-of" => "acct_123" })
  #   rfi.status                           # => "ACTION_REQUIRED"
  #   rfi.active_request[:questions].first # => { id: ..., title: { en: ... }, ... }
  #
  # @example List open RFIs, following every page
  #   Airwallex::RFI.list(
  #     { statuses: "ACTION_REQUIRED" },
  #     headers: { "x-on-behalf-of" => "acct_123" }
  #   ).auto_paging_each { |rfi| puts rfi.id }
  #
  # @example Respond to an RFI (upload any documents first, see UploadedFile)
  #   # Every question in active_request must be answered. Answer types:
  #   # TEXT, ATTACHMENT, IDENTITY_DOCUMENT, CONFIRMATION, LIVENESS, ADDRESS.
  #   # Any answer can also carry a comment:. LIVENESS has no answer body:
  #   # complete the liveness check at question[:liveness][:url] first (an
  #   # RFI whose only question is LIVENESS resolves itself), then respond
  #   # to the rest.
  #   rfi.respond(
  #     {
  #       questions: [
  #         { id: "q1", answer: { type: "TEXT", text: "..." } },
  #         { id: "q2", answer: { type: "ATTACHMENT", attachments: [{ file_id: file.file_id }] } },
  #         { id: "q3", answer: { type: "CONFIRMATION", confirmed: true } },
  #         { id: "q4", answer: { type: "ADDRESS", address: { address_line1: "...", address_line2: "...",
  #                                                           suburb: "...", state: "...", postcode: "...",
  #                                                           country_code: "AU" } } },
  #         { id: "q5", answer: { type: "IDENTITY_DOCUMENT",
  #                               identity_document: { type: "PASSPORT", number: "...", issuing_country: "AU",
  #                                                    front_file_id: "...", back_file_id: "..." } } }
  #       ]
  #     },
  #     headers: { "x-on-behalf-of" => "acct_123" }
  #   )
  #   rfi.status # => "ANSWERED"
  #
  # Responding: the lifecycle is ACTION_REQUIRED -> ANSWERED -> CLOSED
  # (an RFI also moves to CLOSED when active_request.expires_at passes).
  # Responding needs the risk.rfi:write scope. Errors:
  # - invalid_state_for_operation (400): the RFI isn't ACTION_REQUIRED
  # - invalid_argument (400): a question is unanswered, or an answer has
  #   the wrong shape (e.g. TEXT vs ATTACHMENT)
  # - account_not_authorised_for_operation (403): the RFI isn't linked to
  #   the account, or answering RFIs for connected accounts through the
  #   Native API hasn't been enabled (ask your Airwallex Account Manager)
  #
  # @example Raise a KYC RFI, then close it
  #   rfi = Airwallex::RFI.simulate_create(
  #     type: "KYC",
  #     questions: [{ answer: { type: "TEXT" } }]
  #   )
  #   rfi.simulate_close
  class RFI < APIResource
    extend APIOperations::Retrieve
    extend APIOperations::List

    # Sandbox-only — see https://www.airwallex.com/docs/api/simulation/request-for-information
    SIMULATION_PATH = "/api/v1/simulation/rfis"

    # @return [String] API resource path for RFIs
    def self.resource_path
      "/api/v1/rfis"
    end

    # List RFIs. Unlike most resources, RFIs use bookmark pagination: the
    # response carries page_after/page_before instead of has_more/next_cursor,
    # and the next page is requested with page: <page_after>.
    #
    # @param params [Hash] page: (bookmark), page_size: (1-2000, default
    #   100), statuses: / types: (comma-separated strings, e.g.
    #   "ACTION_REQUIRED,ANSWERED"), from_created_at: / end_created_at:
    #   (ISO8601)
    # @param opts [Hash] headers: (e.g. { "x-on-behalf-of" => account_id }),
    #   kept on every subsequent page
    # @return [ListObject<RFI>]
    def self.list(params = {}, opts = {})
      response = Airwallex.client.get(resource_path, params, opts[:headers] || {})
      items = extract_data(response)
      page_after = response.is_a?(Hash) ? response[:page_after] || response["page_after"] : nil

      ListObject.new(
        data: items,
        has_more: !page_after.nil? && !items.empty?,
        next_cursor: page_after,
        cursor_param: :page,
        resource_class: self,
        params: params,
        opts: opts
      )
    end

    # Respond to an RFI. params are sent as-is (see the class docs for the
    # body shape). Unlike other POSTs, no request_id is added: the endpoint
    # doesn't document one.
    #
    # @param rfi_id [String]
    # @param params [Hash] questions: (required) array of { id:, answer: { type:, ... } }
    # @param opts [Hash] headers: (e.g. { "x-on-behalf-of" => account_id })
    # @return [RFI]
    def self.respond(rfi_id, params = {}, opts = {})
      response = Airwallex.client.post("#{resource_path}/#{rfi_id}/respond", without_request_id(params),
                                       opts[:headers] || {})
      new(response)
    end

    # Pre-encode the body as JSON: the Idempotency middleware only adds
    # request_id to Hash bodies, and the JSON middleware passes strings on
    # unchanged
    #
    # @param params [Hash]
    # @return [String]
    def self.without_request_id(params)
      JSON.generate(params)
    end
    private_class_method :without_request_id

    # Simulate Airwallex raising an RFI
    #
    # @param params [Hash] type: (required, one of "KYC", "KYC_ONGOING",
    #   "CARDHOLDER", "TRANSACTION", "PAYMENT_ENABLEMENT",
    #   "MERCHANT_RISK"); questions: (required, array of
    #   { answer: { type: }, sources: [] })
    # @param opts [Hash] headers: (e.g. { "x-on-behalf-of" => account_id })
    # @return [RFI]
    def self.simulate_create(params = {}, opts = {})
      response = Airwallex.client.post("#{SIMULATION_PATH}/create", params, opts[:headers] || {})
      new(response)
    end

    # Simulate closing an RFI
    #
    # @param rfi_id [String]
    # @param opts [Hash] headers: (e.g. { "x-on-behalf-of" => account_id })
    # @return [RFI]
    def self.simulate_close(rfi_id, opts = {})
      response = Airwallex.client.post("#{SIMULATION_PATH}/#{rfi_id}/close", {}, opts[:headers] || {})
      new(response)
    end

    # Simulate a follow-up on an RFI — reopen an existing answered question
    # (by id) or append a new one
    #
    # @param rfi_id [String]
    # @param params [Hash] questions: (required, array of
    #   { id: } or { answer: { type: }, sources: [] })
    # @param opts [Hash] headers: (e.g. { "x-on-behalf-of" => account_id })
    # @return [RFI]
    def self.simulate_follow_up(rfi_id, params = {}, opts = {})
      response = Airwallex.client.post("#{SIMULATION_PATH}/#{rfi_id}/follow_up", params, opts[:headers] || {})
      new(response)
    end

    # Respond to this RFI. See .respond
    #
    # @param params [Hash] questions: (required)
    # @param opts [Hash] headers: (e.g. { "x-on-behalf-of" => account_id })
    # @return [RFI] self
    def respond(params = {}, opts = {})
      refresh_from(self.class.respond(id, params, opts).to_hash)
      self
    end

    # Simulate closing this RFI
    #
    # @param opts [Hash] headers: (e.g. { "x-on-behalf-of" => account_id })
    # @return [RFI] self
    def simulate_close(opts = {})
      response = Airwallex.client.post("#{SIMULATION_PATH}/#{id}/close", {}, opts[:headers] || {})
      refresh_from(response)
      self
    end

    # Simulate a follow-up on this RFI
    #
    # @param params [Hash] questions: (required)
    # @param opts [Hash] headers: (e.g. { "x-on-behalf-of" => account_id })
    # @return [RFI] self
    def simulate_follow_up(params = {}, opts = {})
      response = Airwallex.client.post("#{SIMULATION_PATH}/#{id}/follow_up", params, opts[:headers] || {})
      refresh_from(response)
      self
    end
  end
end
