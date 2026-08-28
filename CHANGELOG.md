## [Unreleased]

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
