## [Unreleased]

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
