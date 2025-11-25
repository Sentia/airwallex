# Sprint 3 Plan - Refunds & Payment Methods
**Date:** November 25, 2025
**Sprint:** 3 - Enhanced Payment Operations
**Status:** 📋 Planning

---

## Objectives

Build out critical payment lifecycle features that complement the existing PaymentIntent resource:
1. **Refund** resource for payment reversals
2. **PaymentMethod** resource for stored payment credentials
3. Enhanced error handling with automatic retries

These additions will make the gem production-ready for complete payment acceptance flows.

---

## Why These Features?

### Priority Rationale
1. **Refunds** - Essential for production use; every merchant needs refund capability
2. **PaymentMethod** - Required for recurring payments and returning customers
3. **Retry Logic** - Production resilience for network issues and rate limits

### User Stories
- As a merchant, I need to refund customers when they return products
- As a platform, I want to store customer payment methods for subscriptions
- As a developer, I need automatic retry on transient failures

---

## Implementation Plan

### 1. Refund Resource ⏳

**Endpoints:**
- `POST /api/v1/pa/refunds/create` - Create refund for a payment intent
- `GET /api/v1/pa/refunds/{id}` - Retrieve refund details
- `GET /api/v1/pa/refunds` - List refunds with pagination

**File:** `lib/airwallex/resources/refund.rb`

**API Operations:** Create, Retrieve, List

**Key Attributes:**
```ruby
{
  id: "rfd_123",
  payment_intent_id: "pi_123",
  amount: 50.00,
  currency: "USD",
  reason: "requested_by_customer",
  status: "succeeded", # pending, succeeded, failed
  created_at: "2025-11-25T10:00:00Z"
}
```

**Methods:**
```ruby
# Create refund
refund = Airwallex::Refund.create(
  payment_intent_id: "pi_123",
  amount: 50.00,
  reason: "requested_by_customer"
)

# Partial refund support
refund = Airwallex::Refund.create(
  payment_intent_id: "pi_123",
  amount: 25.00  # Partial refund
)

# List refunds for a payment
refunds = Airwallex::Refund.list(payment_intent_id: "pi_123")

# Retrieve specific refund
refund = Airwallex::Refund.retrieve("rfd_123")
```

**Relationships:**
- Belongs to PaymentIntent
- Multiple refunds per payment (up to original amount)

---

### 2. PaymentMethod Resource ⏳

**Endpoints:**
- `POST /api/v1/pa/payment_methods/create` - Store payment method
- `GET /api/v1/pa/payment_methods/{id}` - Retrieve payment method
- `GET /api/v1/pa/payment_methods` - List customer's payment methods
- `PUT /api/v1/pa/payment_methods/{id}` - Update payment method (billing details)
- `DELETE /api/v1/pa/payment_methods/{id}` - Detach/delete payment method

**File:** `lib/airwallex/resources/payment_method.rb`

**API Operations:** Create, Retrieve, List, Update, Delete

**Key Attributes:**
```ruby
{
  id: "pm_123",
  type: "card",
  card: {
    brand: "visa",
    last4: "4242",
    expiry_month: "12",
    expiry_year: "2025",
    country: "US"
  },
  billing: {
    first_name: "John",
    last_name: "Doe",
    email: "john@example.com",
    address: { ... }
  },
  customer_id: "cus_123",
  created_at: "2025-11-25T10:00:00Z"
}
```

**Methods:**
```ruby
# Create card payment method
pm = Airwallex::PaymentMethod.create(
  type: "card",
  card: {
    number: "4242424242424242",
    expiry_month: "12",
    expiry_year: "2025",
    cvc: "123"
  },
  billing: {
    first_name: "John",
    email: "john@example.com"
  }
)

# Use saved payment method
payment_intent.confirm(payment_method_id: pm.id)

# List customer's payment methods
methods = Airwallex::PaymentMethod.list(customer_id: "cus_123")

# Update billing details
pm.update(billing: { address: { postal_code: "10001" } })

# Delete payment method
pm.delete
# or
Airwallex::PaymentMethod.delete("pm_123")
```

**Security Notes:**
- Full card details only available on creation
- Subsequent retrieves only return last4 and metadata
- PCI compliance maintained by Airwallex

---

### 3. Enhanced Error Handling ⏳

**File:** `lib/airwallex/middleware/retry.rb`

**Features:**
- Automatic retry with exponential backoff
- Jittered delays to prevent thundering herd
- Configurable retry limits
- Idempotency-aware retries

**Implementation:**
```ruby
# Use faraday-retry middleware
connection.use Faraday::Retry::Middleware,
  max: 3,
  interval: 0.5,
  backoff_factor: 2,
  exceptions: [
    Airwallex::RateLimitError,
    Airwallex::APIConnectionError,
    Faraday::TimeoutError
  ],
  methods: [:get, :post, :put, :patch, :delete],
  retry_if: lambda { |env, exception|
    # Don't retry 4xx errors except 429 (rate limit)
    return false if env.status && (400..499).cover?(env.status) && env.status != 429
    true
  }
```

**Configuration:**
```ruby
Airwallex.configure do |config|
  config.max_retries = 3
  config.retry_interval = 0.5  # seconds
  config.timeout = 30  # seconds
end
```

---

### 4. Customer Resource (Optional) ⏳

**Why:** PaymentMethods need to belong to Customers for proper organization

**Endpoints:**
- `POST /api/v1/pa/customers/create`
- `GET /api/v1/pa/customers/{id}`
- `GET /api/v1/pa/customers`
- `PUT /api/v1/pa/customers/{id}`
- `DELETE /api/v1/pa/customers/{id}`

**Key Attributes:**
```ruby
{
  id: "cus_123",
  email: "customer@example.com",
  first_name: "John",
  last_name: "Doe",
  metadata: { internal_id: "user_789" }
}
```

**Methods:**
```ruby
# Create customer
customer = Airwallex::Customer.create(
  email: "john@example.com",
  first_name: "John",
  last_name: "Doe"
)

# Retrieve customer
customer = Airwallex::Customer.retrieve("cus_123")

# List payment methods for customer
methods = customer.payment_methods
```

---

## Testing Strategy

### Unit Tests (New)
- `spec/airwallex/resources/refund_spec.rb` (~150 lines)
  - Create, retrieve, list operations
  - Partial refund scenarios
  - Error handling (already refunded, insufficient amount)

- `spec/airwallex/resources/payment_method_spec.rb` (~200 lines)
  - CRUD operations
  - Card tokenization
  - Multiple payment method types
  - Customer association

- `spec/airwallex/resources/customer_spec.rb` (~120 lines)
  - CRUD operations
  - Payment method listing
  - Metadata management

- `spec/airwallex/middleware/retry_spec.rb` (~100 lines)
  - Exponential backoff verification
  - Retry limit enforcement
  - Idempotency preservation

### Integration Tests
- Manual test script in `local_tests/test_refunds.rb`
- Test with sandbox environment
- Verify refund states and webhooks

---

## File Structure

```
lib/airwallex/
├── resources/
│   ├── payment_intent.rb      # Existing
│   ├── transfer.rb             # Existing
│   ├── beneficiary.rb          # Existing
│   ├── refund.rb              # NEW - Sprint 3
│   ├── payment_method.rb      # NEW - Sprint 3
│   └── customer.rb            # NEW - Sprint 3
├── middleware/
│   ├── idempotency.rb         # Existing
│   └── retry.rb               # NEW - Sprint 3
└── errors.rb                  # Update with new errors

spec/airwallex/
├── resources/
│   ├── payment_intent_spec.rb # Existing
│   ├── transfer_spec.rb       # Existing
│   ├── beneficiary_spec.rb    # Existing
│   ├── refund_spec.rb         # NEW - Sprint 3
│   ├── payment_method_spec.rb # NEW - Sprint 3
│   └── customer_spec.rb       # NEW - Sprint 3
└── middleware/
    ├── idempotency_spec.rb    # Existing
    └── retry_spec.rb          # NEW - Sprint 3
```

---

## API Research Required

### Documentation Review
1. Refund API specifics:
   - Partial vs full refund rules
   - Refund status lifecycle
   - Webhook events for refunds

2. PaymentMethod API:
   - Card vs other method types
   - Tokenization flow
   - Security model

3. Customer API:
   - Required vs optional fields
   - Metadata limits
   - Deletion rules

### Endpoint Testing
- Test all endpoints in sandbox
- Document response formats
- Note any undocumented behaviors

---

## Success Criteria

### Functional
- ✅ Refunds can be created and tracked
- ✅ Payment methods can be stored and reused
- ✅ Customers can be managed
- ✅ Automatic retry works for transient failures

### Quality
- ✅ All new tests passing (expect ~400 total tests)
- ✅ 0 Rubocop offenses maintained
- ✅ Documentation updated with examples
- ✅ CHANGELOG updated

### User Experience
- ✅ Intuitive API matching Stripe patterns
- ✅ Clear error messages
- ✅ Good examples in README

---

## Timeline Estimate

### Phase 1: Research & Design (Day 1)
- Review Airwallex documentation
- Test endpoints in sandbox
- Finalize API design

### Phase 2: Implementation (Day 2-3)
- Implement Refund resource
- Implement PaymentMethod resource
- Implement Customer resource
- Add retry middleware

### Phase 3: Testing (Day 4)
- Write comprehensive unit tests
- Manual integration testing
- Update documentation

### Phase 4: Release (Day 5)
- Final review
- Update CHANGELOG for v0.2.0
- Publish gem

---

## Post-Sprint 3 Roadmap

### Sprint 4 Ideas
1. **Foreign Exchange** - Rates, quotes, conversions
2. **Batch Operations** - Batch transfers for payroll
3. **Webhooks Enhancement** - Event subscription management
4. **Global Accounts** - Virtual account provisioning

### Sprint 5+ Ideas
- Card issuing
- Advanced reporting
- Multi-currency wallets
- Dispute management

---

## Questions for Consideration

1. Should Customer be part of Sprint 3 or deferred?
2. Do we need PaymentAttempt resource tracking?
3. Should we add dispute/chargeback handling?
4. What's the priority for recurring payment schedules?

---

**Next Action:** Begin Refund resource implementation
