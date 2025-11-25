# Sprint 1 Implementation Plan

## Overview

Sprint 1 focuses on establishing the foundational architecture of the Airwallex Ruby gem, including core infrastructure, authentication mechanisms, and basic API communication capabilities. This sprint prioritizes correctness, idempotency, and type safety as outlined in the architectural blueprint.

## Sprint Goals

1. Establish core gem architecture and configuration system
2. Implement authentication and token lifecycle management
3. Build HTTP transport layer with Faraday
4. Create error handling framework
5. Implement idempotency middleware
6. Set up testing infrastructure

## Sprint Duration

2 weeks

## Work Items

### 1. Core Architecture Setup

**Priority: Critical**

#### 1.1 Gem Structure and Module Organization

- Create directory structure following the architectural blueprint:
  ```
  lib/airwallex/
  ├── api_operations/
  ├── resources/
  ├── errors.rb
  ├── client.rb
  ├── configuration.rb
  ├── webhook.rb
  ├── util.rb
  ├── middleware/
  │   ├── auth_refresh.rb
  │   └── idempotency.rb
  └── version.rb
  ```

- Set up `lib/airwallex.rb` as main entry point with configuration block support

**Acceptance Criteria:**
- Directory structure matches blueprint
- Module can be required without errors
- Configuration block accepts environment, api_key, client_id

**Estimated Effort:** 2 hours

#### 1.2 Configuration Management

- Implement `Airwallex::Configuration` class
- Support environment selection (`:sandbox`, `:production`)
- Dynamic URL generation based on environment
- Default to `:sandbox` for safety
- Validate credential format

**Key Features:**
```ruby
Airwallex.configure do |config|
  config.api_key = 'key'
  config.client_id = 'id'
  config.environment = :sandbox
  config.api_version = '2024-09-27'  # Date-based versioning
end
```

**Acceptance Criteria:**
- Configuration persists across requests
- Environment correctly maps to URLs (api-demo vs api)
- Raises error if credentials missing
- Validates environment is :sandbox or :production

**Estimated Effort:** 4 hours

### 2. HTTP Transport Layer

**Priority: Critical**

#### 2.1 Faraday Client Setup

- Configure Faraday connection with TLS 1.2+ enforcement
- Set base URLs for API and Files endpoints
- Configure default headers:
  - `Content-Type: application/json`
  - `User-Agent: Airwallex-Ruby/{version} Ruby/{ruby_version}`
  - `x-api-version` from configuration

**Acceptance Criteria:**
- Faraday connection established
- Headers correctly injected
- TLS version enforced
- Base URL switches with environment

**Estimated Effort:** 3 hours

#### 2.2 Request/Response Middleware Stack

- JSON request encoding
- JSON response parsing
- Logging middleware (debug mode)
- Configure connection and request timeouts

**Acceptance Criteria:**
- JSON automatically serialized/deserialized
- Logs show request/response in debug mode
- Timeouts configurable

**Estimated Effort:** 3 hours

### 3. Authentication System

**Priority: Critical**

#### 3.1 Bearer Token Authentication

- Implement `Airwallex::Authentication` module
- POST to `/api/v1/authentication/login`
- Exchange client_id/api_key for Bearer token
- Store token and expiration

**Key Implementation:**
```ruby
POST /api/v1/authentication/login
Headers: x-client-id, x-api-key
Response: { token: "...", expires_at: "..." }
```

**Acceptance Criteria:**
- Successful token exchange
- Token stored in client instance
- Expiration time tracked
- Handles 401 authentication errors

**Estimated Effort:** 4 hours

#### 3.2 Token Lifecycle Management Middleware

- Implement `Airwallex::Middleware::AuthRefresh`
- Check token expiration before requests (5-minute buffer)
- Auto-refresh expired tokens
- Intercept 401 responses and retry once after refresh
- Thread-safe token management

**Acceptance Criteria:**
- Token refreshes automatically when expired
- 401 responses trigger refresh and retry
- No double-refresh in concurrent requests
- Transparent to end user

**Estimated Effort:** 6 hours

### 4. Error Handling Framework

**Priority: Critical**

#### 4.1 Exception Hierarchy

Create exception classes mapped to HTTP status codes:

```ruby
Airwallex::Error (base)
├── Airwallex::BadRequestError (400)
├── Airwallex::AuthenticationError (401)
├── Airwallex::PermissionError (403)
├── Airwallex::NotFoundError (404)
├── Airwallex::RateLimitError (429)
└── Airwallex::APIError (500+)
```

**Acceptance Criteria:**
- All error classes defined
- Base error has code, message, param, details attributes
- HTTP status correctly mapped to exception class

**Estimated Effort:** 3 hours

#### 4.2 Error Response Parsing

- Handle polymorphic error body structures
- Parse standard errors: `{ code, message, source }`
- Parse complex errors with details array
- Parse validation errors with nested source paths
- Map `source` to `param` attribute

**Test Cases:**
- Simple error: `{ code: "insufficient_fund", message: "..." }`
- Complex error: `{ code: "request_id_duplicate", details: [...] }`
- Validation error: `{ code: "invalid_argument", source: "nested.field.path" }`

**Acceptance Criteria:**
- All error formats parsed correctly
- Detailed error information accessible
- Source field mapped to param

**Estimated Effort:** 4 hours

### 5. Idempotency System

**Priority: High**

#### 5.1 Idempotency Middleware

- Implement `Airwallex::Middleware::Idempotency`
- Auto-generate UUID v4 for `request_id` if not provided
- Inject `request_id` into request body (not headers)
- Preserve user-provided request_id for reconciliation

**Key Behavior:**
```ruby
# User doesn't provide request_id
Transfer.create(amount: 100) 
# Gem generates: { amount: 100, request_id: "uuid-v4" }

# User provides request_id
Transfer.create(amount: 100, request_id: "my-id")
# Gem preserves: { amount: 100, request_id: "my-id" }
```

**Acceptance Criteria:**
- UUID v4 generated if request_id missing
- User-provided request_id preserved
- request_id injected into body, not headers
- Works for POST/PUT/PATCH methods only

**Estimated Effort:** 4 hours

#### 5.2 Retry Logic with Idempotency

- Implement retry middleware with exponential backoff
- Safe retries for GET requests on 429, 5xx
- Safe retries for POST/PUT/PATCH only if request_id present
- Jittered exponential backoff (prevents thundering herd)
- Max 3 retry attempts

**Acceptance Criteria:**
- GET requests retried on 429/5xx
- POST with request_id retried safely
- POST without request_id NOT retried
- Backoff includes jitter
- Max retries configurable

**Estimated Effort:** 5 hours

### 6. Testing Infrastructure

**Priority: High**

#### 6.1 Test Setup

- Configure RSpec with spec_helper
- Add WebMock for HTTP stubbing
- Add VCR for recording/replaying HTTP interactions
- Create test fixtures for common responses
- Set up test coverage reporting

**Acceptance Criteria:**
- RSpec runs successfully
- WebMock blocks real HTTP requests
- VCR configured for sandbox interactions
- Test coverage tracked

**Estimated Effort:** 3 hours

#### 6.2 Core Tests

Write comprehensive tests for:

- Configuration management
- Authentication flow
- Token refresh logic
- Error parsing (all formats)
- Idempotency key generation
- Retry logic with various scenarios

**Test Coverage Targets:**
- Configuration: 100%
- Authentication: 100%
- Error handling: 100%
- Middleware: 95%+

**Acceptance Criteria:**
- All core components tested
- Edge cases covered
- VCR cassettes for sandbox API
- Coverage above 90%

**Estimated Effort:** 8 hours

### 7. Utility Modules

**Priority: Medium**

#### 7.1 Date/Time Formatting

- Implement ISO 8601 serialization helpers
- Accept Ruby Date, Time, DateTime objects
- Convert to "YYYY-MM-DDTHH:MM:SSZ" format
- Handle timezone conversions

**Acceptance Criteria:**
- Date/Time objects serialized correctly
- ISO 8601 format enforced
- Timezone handling accurate

**Estimated Effort:** 2 hours

#### 7.2 BigDecimal Support

- Configure JSON serialization for BigDecimal
- Add helpers for currency conversion
- Documentation on monetary value handling

**Acceptance Criteria:**
- BigDecimal serialized without precision loss
- Helper methods available
- Documentation clear

**Estimated Effort:** 2 hours

## Definition of Done

- [ ] All code follows Rubocop style guide (no offenses)
- [ ] Test coverage above 90%
- [ ] All acceptance criteria met
- [ ] Documentation updated in README
- [ ] Code reviewed by team member
- [ ] Manual testing in sandbox environment
- [ ] No security vulnerabilities (bundle audit clean)

## Dependencies and Risks

### Dependencies

- Faraday ~> 2.0
- Faraday-multipart ~> 1.0
- Faraday-retry ~> 2.0
- RSpec ~> 3.12 (dev)
- WebMock ~> 3.18 (dev)
- VCR ~> 6.1 (dev)

### Risks

1. **Token refresh race conditions**: Mitigated with mutex locks
2. **Idempotency key collisions**: Use UUID v4 (collision probability negligible)
3. **API version changes**: Pin to specific tested version (2024-09-27)
4. **Rate limiting during testing**: Use VCR to replay responses

## Success Metrics

- Core architecture complete and testable
- Authentication works reliably in sandbox
- Idempotency prevents duplicate transactions
- Error handling provides actionable information
- All tests pass consistently
- Zero Rubocop offenses

## Out of Scope for Sprint 1

The following items are deferred to future sprints:

- Specific resource implementations (Payment, Transfer, etc.)
- Pagination logic (AutoPaginator)
- Webhook signature verification
- OAuth flow support
- SCA token handling
- Platform/Connected Account features (x-on-behalf-of)
- Rate limit headers parsing
- API version override per-request

## Sprint Retrospective Topics

- Was the architectural approach correct?
- Are the abstractions at the right level?
- Is the error handling sufficient?
- How maintainable is the middleware stack?
- What surprised us during implementation?

## Next Sprint Preview

Sprint 2 will focus on:
- Resource base class (APIResource)
- API operations mixins (Create, Retrieve, List)
- Pagination system (cursor and offset)
- First resource implementations (Payment Intent, Transfer)
- Webhook verification
