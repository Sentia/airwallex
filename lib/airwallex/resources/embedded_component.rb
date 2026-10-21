# frozen_string_literal: true

module Airwallex
  # Server-side support for Airwallex embedded components (the beneficiary,
  # payout, onboarding, KYB, RFI, SCA and tax form UI components). The
  # browser SDK needs an authorization code minted by your backend; this
  # class mints it. See
  # https://www.airwallex.com/docs/api/authentication/embedded_components/authorize
  #
  # Scopes: transfer:write (beneficiary and payout components),
  # onboarding:write, kyb:write, rfi:read, rfi:write, sca:read, sca:write,
  # tax_form:read, tax_form:write.
  #
  # @example Authorize the payout component for a connected account
  #   code_verifier = SecureRandom.urlsafe_base64(64)
  #   code_challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier), padding: false)
  #
  #   Airwallex::EmbeddedComponent.authorize(
  #     code_challenge: code_challenge,
  #     scope: ["transfer:write"],
  #     headers: { "x-on-behalf-of" => "acct_123" }
  #   )
  #   # => { authorization_code: "..." }
  class EmbeddedComponent < APIResource
    AUTHORIZE_PATH = "/api/v1/authentication/authorize"

    # Issue a single-use authorization code for an embedded component. The
    # code expires in 30 seconds; hand it, with the code_verifier, to the
    # browser SDK straight away. Unlike other POSTs, no request_id is added:
    # the endpoint doesn't document one.
    #
    # @param code_challenge [String] BASE64URL(SHA256(code_verifier)), the
    #   PKCE S256 challenge (RFC 7636 section 4)
    # @param scope [Array<String>] e.g. ["transfer:write"]
    # @param identity [String, nil] only used by embedded SCA
    # @param headers [Hash] e.g. { "x-on-behalf-of" => account_id }; without
    #   it the code is issued for the platform account
    # @return [Hash] { authorization_code: }
    def self.authorize(code_challenge:, scope:, identity: nil, headers: {})
      params = { code_challenge: code_challenge, scope: scope }
      params[:identity] = identity if identity

      # Pre-encoded so the Idempotency middleware (Hash bodies only) skips it
      symbolized_post(AUTHORIZE_PATH, JSON.generate(params), headers)
    end
  end
end
