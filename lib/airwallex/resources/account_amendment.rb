# frozen_string_literal: true

module Airwallex
  # Represents an amendment to whichever account the request is
  # authenticated as (the platform's own account, or a connected account via
  # x-on-behalf-of). Not nested under /accounts/{id} — scoped implicitly by
  # auth context, same as ConnectedAccount.current.
  #
  # .create requires Admin-level API key permissions, a separate tier from
  # the normal per-resource Read/Write scopes.
  #
  # @example Submit an amendment
  #   # `target` identifies the dotted path being amended; the changed
  #   # section is a top-level sibling keyed by its own name (e.g.
  #   # store_details), not wrapped in a generic "changes" key.
  #   amendment = Airwallex::AccountAmendment.create(
  #     target: "account_details.store_details",
  #     store_details: { store_name: "New Store Name" }
  #   )
  class AccountAmendment < APIResource
    extend APIOperations::Create
    extend APIOperations::Retrieve

    # @return [String] API resource path for account amendments
    def self.resource_path
      "/api/v1/account/amendments"
    end
  end
end
