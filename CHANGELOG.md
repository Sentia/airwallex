## [Unreleased]

## [0.8.0] - 2026-09-02

### Fixed
- `Util.deep_symbolize_keys` now recurses into `Array`s, matching `ActiveSupport#deep_transform_keys`'s
  behavior. Previously any `Array` value was copied through untouched, so hashes nested inside an array
  (e.g. `beneficiary_form_schemas`'s `fields` list) kept string keys even after "deep" symbolizing.
- `Beneficiary.validate`, `.verify_account`, `.api_schema`, `.form_schema`, and
  `.supported_financial_institutions`, `ConnectedAccount.wallet_info`, `BillingCustomer#bank_transfer_instructions`,
  and `GlobalAccount#generate_statement_letter` now return `Util.deep_symbolize_keys`-processed responses.
  Previously these methods (unlike `.create`/`.retrieve`/`.update`/`.delete`/`.list`, which already
  funnel through `APIResource`'s symbolization) returned the raw parsed JSON response with string keys,
  with nothing in the method signature or naming to distinguish them from the symbolized methods on the
  same class.

  **Breaking change:** any code reading these eight methods' return values with string keys
  (`response["field"]`) must switch to symbol keys (`response[:field]`).

### Follow-up (not included in this release)
- `Airwallex::Error#details`/`#param` are still populated from the raw, unsymbolized error body and are
  intentionally out of scope here — a downstream consumer reads `#details` with string keys today, so
  changing this needs a coordinated PR on that side first.

## [0.7.0] - 2026-08-28

### Added
- GlobalAccount resource (create, retrieve, list, update, `#close`, `#generate_statement_letter`,
  `#transactions`)
  - GlobalAccountAlias nested resource (`#create_alias`, `#alias`, `#aliases`, `#initiate_port`,
    `#submit_verification_code`, `#request_new_verification_code`, `#cancel`)
  - GlobalAccountMandate nested resource (`#mandate`, `#mandates`, `#cancel`)
- Billing resources: BillingCustomer, BillingProduct, BillingPrice, BillingSubscription (with `#items`/`#item`)
- PaymentConsent resource (create, retrieve, list, update, `#verify`, `#verify_continue`, `#disable`)
- PaymentSource resource (create, retrieve, list)
- ConnectedAccount resource (create, retrieve, list, update, `#submit`, `#agree_to_terms_and_conditions`,
  `#suspend`, `#reactivate`, `.current`, `.wallet_info`, `#legal_entity_id`)
- AccountAmendment resource (create, retrieve)
- FundsSplit resource (create, retrieve, list, `#release`)
- Charge resource (create, retrieve, list)
- Beneficiary gained `.update`/`#update`, `.validate`, `.verify_account`, `.api_schema`, `.form_schema`, and
  `.supported_financial_institutions`
- Dispute gained `.update`, `#challenge` (replacing `#submit_evidence`), and `#related_payment_intents`
- PaymentMethod gained `#disable`
- New tests covering all of the above (378 total)

### Fixed
- `APIOperations::Update` now sends `POST #{resource_path}/{id}/update` instead of `PUT #{resource_path}/{id}`
- `APIOperations::Delete` now sends `POST #{resource_path}/{id}/delete` instead of `DELETE #{resource_path}/{id}`,
  and checks the response instead of always returning `true`
- `Dispute`'s resource path corrected from `/api/v1/disputes` to `/api/v1/pa/payment_disputes`
- `Conversion`'s resource path corrected from `/api/v1/conversions` to `/api/v1/fx/conversions`
- `Configuration#api_version` now defaults to `nil` instead of a hardcoded date, and `x-api-version` is only
  sent when explicitly set
- `Beneficiary.create`/`.validate`/`.update` payloads corrected: wrapped under a top-level `beneficiary` key,
  with `nickname`/`payer_entity_type`/`transfer_methods`/`transfer_reason` as top-level siblings;
  `entity_type` replaces the nonexistent `beneficiary_type`
- `Beneficiary#update`/`.update` requires the full payload, not a partial patch
- `Beneficiary.supported_financial_institutions` requires `account_currency`, `entity_type`,
  `transfer_method`, and `keyword` in addition to `bank_country_code`
- `Customer.create` requires `merchant_customer_id`
- `GlobalAccount#generate_statement_letter` requires `account_statement_type` and `registration_info`
- `ConnectedAccount.create` payload corrected: `account_details` is a required top-level wrapper;
  `legal_entity_type` is `"BUSINESS"`/`"INDIVIDUAL"`, not `"COMPANY"`
- `BillingCustomer.create` payload corrected to match the real flat schema (`name`/`email`/`type`/
  `default_billing_currency`/`address`/`default_legal_entity_id`)
- `BillingPrice.create` requires `pricing_model` and `recurring`
- `BillingSubscription.create` payload corrected: prices attach via an `items:` array, not a flat
  `price_id`; `starts_at` replaces `start_date`; added `legal_entity_id` and `payment_source_id`
- `AccountAmendment.create` payload corrected to use `target` plus the changed section as a top-level
  sibling, not a generic `changes:` wrapper
- `PaymentSource.create`'s `external_id` corrected to reference a `PaymentMethod` id, not a `PaymentConsent` id
- `ConnectedAccount#legal_entity_id` added as the source for `BillingCustomer`/`BillingSubscription`'s
  `legal_entity_id`, rather than a separate resource
- `Rate`/`Quote` use `sell_currency`/`buy_currency`, not `from_currency`/`to_currency`
- `Quote.create` requires `validity` (`MIN_1`, `MIN_15`, `MIN_30`, `HR_1`, `HR_4`, `HR_8`, or `HR_24`)

### Removed
- `Rate.list` — the endpoint has no "list all rates" concept, only `.retrieve(sell_currency:, buy_currency:)`
- `PaymentMethod.delete` and `PaymentMethod#detach` — replaced by `#disable`, the real lifecycle operation

## [0.6.0] - 2026-08-28

### Fixed
- `Webhook::Event` now correctly exposes the event type. Airwallex sends this field as `"name"` in
  the webhook payload, not `"type"` — the previous `Event#type` reader was reading a key that doesn't
  exist and always returned `nil`. The accessor is renamed to `Event#name` to match Airwallex's actual
  field. **Breaking change:** `event.type` → `event.name`.

## [0.5.0] - 2026-08-28

### Fixed
- Webhook signature verification no longer rejects valid webhooks when Airwallex sends
  millisecond-precision timestamps. `verify_timestamp` now detects millisecond values (anything at or
  above `MS_THRESHOLD = 10_000_000_000`, which safely distinguishes seconds from milliseconds until the
  year 2286) and normalizes them to seconds before comparing against the tolerance window.

## [0.4.0] - 2026-08-27

### Fixed
- `Idempotency` and `AuthRefresh` middleware are now actually registered on the Faraday connection.
  Previously both classes existed but were never wired in, so the "automatic `request_id` generation"
  and "retry once after a 401" behavior documented in the README did not happen at runtime.
- Fixed a bug in `AuthRefresh` where the 401-retry guard used `env[:request][:auth_retry]`, a key that
  doesn't exist on `Faraday::RequestOptions` and would have raised `NoMethodError` the first time it ran.
- CI now triggers on pushes to `main` (previously configured for `master`, so pushes never ran CI).

### Changed
- `Client#request` no longer manually manages the `Authorization` header or calls
  `ensure_authenticated!` directly; this is now owned by the `AuthRefresh` middleware.

## [0.3.0] - 2025-11-25

### Added
- BatchTransfer resource (create, retrieve, list) for bulk payout operations
- Dispute resource (retrieve, list, accept, submit_evidence) for chargeback management
- Foreign Exchange resources:
  - Rate resource (retrieve, list) for real-time exchange rate queries
  - Quote resource (create, retrieve) for locking exchange rates with expiration helpers
  - Conversion resource (create, retrieve, list) for executing currency conversions
  - Balance resource (list, retrieve) for querying account balances across currencies
- Enhanced List operation to handle both array responses and paginated responses
- 63 new tests (278 total) covering batch transfers, disputes, FX, and balance operations
- Comprehensive manual test suite for regression testing

### Changed
- Refactored List operation for better code quality (reduced complexity from 12 to 7)
- Balance.retrieve now performs client-side filtering for currency lookup

### Fixed
- List operation now correctly handles Balance API's direct array response format

## [0.2.0] - 2025-11-25

### Added
- Refund resource (create, retrieve, list)
- PaymentMethod resource (create, retrieve, list, update, delete, detach)
- Customer resource (create, retrieve, list, update, delete)
- Customer#payment_methods convenience method
- 28 new tests (215 total)

## [0.1.0] - 2025-11-25

### Added
- Core infrastructure: Configuration, Client, Error handling
- Authentication: Bearer token with automatic refresh
- API Resources:
  - PaymentIntent (create, retrieve, list, update, confirm, cancel, capture)
  - Transfer (create, retrieve, list, cancel)
  - Beneficiary (create, retrieve, list, delete)
- API Operations: Reusable mixins for Create, Retrieve, List, Update, Delete
- Pagination: Unified ListObject with auto-paging support (cursor and offset-based)
- Idempotency: Automatic request_id generation for safe retries
- Webhook verification: HMAC-SHA256 signature validation
- Multi-environment support: Sandbox and Production
- Comprehensive test suite: 187 tests with 100% coverage
- Ruby 3.1+ support

### Notes
- This is an MVP release focusing on core payment acceptance and payout functionality
- Additional resources (FX, cards, refunds) will be added in future versions
