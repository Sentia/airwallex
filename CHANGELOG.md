## [Unreleased]

## [0.3.0] - 2025-11-25

### Added
- Foreign Exchange resources:
  - Rate resource (retrieve, list) for real-time exchange rate queries
  - Quote resource (create, retrieve) for locking exchange rates with expiration helpers
  - Conversion resource (create, retrieve, list) for executing currency conversions
  - Balance resource (list, retrieve) for querying account balances across currencies
- Enhanced List operation to handle both array responses and paginated responses
- 38 new tests (278 total) covering FX and balance operations
- Comprehensive manual test suite for regression testing

### Changed
- Refactored List operation for better code quality (reduced complexity from 12 to 7)
- Balance.retrieve now performs client-side filtering for currency lookup

### Fixed
- List operation now correctly handles Balance API's direct array response format

## [0.2.1] - 2025-11-25

### Added
- BatchTransfer resource (create, retrieve, list) for bulk payout operations
- Dispute resource (retrieve, list, accept, submit_evidence) for chargeback management
- 25 new tests (240 total) covering batch transfers and disputes

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
