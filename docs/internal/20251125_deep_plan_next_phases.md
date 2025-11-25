# Airwallex Ruby Gem - Deep Plan for Next Phases

**Date:** 2025-11-25  
**Current Version:** 0.2.0  
**Current Test Coverage:** 240 tests passing  
**Status:** Sprint 4 complete, ready for v0.3.0 release or continue development

---

## Executive Summary

The Airwallex Ruby gem has successfully completed 4 sprints, establishing a solid foundation for payment acceptance, payouts, refunds, payment methods, customer management, batch operations, and dispute handling. The gem now covers the core payment lifecycle end-to-end.

**Next strategic decisions:**
1. **Option A**: Release v0.3.0 now (incremental value delivery)
2. **Option B**: Complete Sprint 5 (FX/Balance) first, then release v0.4.0 (larger feature set)

This document provides a comprehensive roadmap for the next 6 sprints, prioritized by business value and technical dependencies.

---

## Current State Assessment

### ✅ Completed Resources (Sprints 1-4)

**Payment Acceptance:**
- PaymentIntent (full CRUD + confirm, cancel, capture)
- Refund (create, retrieve, list)
- PaymentMethod (full CRUD + detach)
- Customer (full CRUD + payment_methods helper)
- Dispute (retrieve, list, accept, submit_evidence)

**Payouts:**
- Transfer (create, retrieve, list, cancel)
- Beneficiary (create, retrieve, list, delete)
- BatchTransfer (create, retrieve, list)

**Infrastructure:**
- Authentication with auto-refresh
- Idempotency with automatic request_id
- Pagination (cursor + offset based)
- Webhook verification (HMAC-SHA256)
- Error handling hierarchy
- Rate limit handling
- Multi-environment support

### 📊 Metrics
- **Resources:** 8 implemented
- **Tests:** 240 passing
- **Code Quality:** 0 Rubocop offenses
- **Coverage:** Core payment flows complete
- **Documentation:** Comprehensive README + API docs

---

## Sprint 5: Foreign Exchange (FX) & Balance Management

**Priority:** HIGH  
**Estimated Effort:** 6-8 hours  
**Business Value:** Critical for multi-currency operations

### Objectives

Enable users to:
1. Check real-time exchange rates
2. Create and lock FX quotes
3. Execute currency conversions
4. Monitor account balances across currencies
5. View balance history and transactions

### Resources to Implement

#### 5.1. Rate Resource

**Endpoint:** `/api/v1/rates`  
**Purpose:** Get real-time indicative exchange rates

**Operations:**
- `retrieve` - Get rate for currency pair
- `list` - Get multiple rates

**Key Fields:**
- `from_currency` - Source currency (e.g., USD)
- `to_currency` - Target currency (e.g., EUR)
- `rate` - Exchange rate
- `inverse_rate` - Reverse rate
- `timestamp` - Rate timestamp

**Usage Example:**
```ruby
# Get current rate
rate = Airwallex::Rate.retrieve(
  from_currency: 'USD',
  to_currency: 'EUR'
)
puts "1 USD = #{rate.rate} EUR"

# Get multiple rates
rates = Airwallex::Rate.list(
  from_currency: 'USD',
  to_currencies: ['EUR', 'GBP', 'JPY']
)
```

**Testing Requirements:**
- Retrieve single rate
- List multiple rates
- Handle invalid currency codes
- Test rate expiration

---

#### 5.2. Quote Resource

**Endpoint:** `/api/v1/quotes`  
**Purpose:** Lock exchange rates for guaranteed conversion

**Operations:**
- `create` - Create and lock a quote
- `retrieve` - Get quote details

**Key Fields:**
- `id` - Quote ID
- `from_currency` - Source currency
- `to_currency` - Target currency
- `buy_amount` / `sell_amount` - Transaction amounts
- `rate` - Locked rate
- `expires_at` - Quote expiration (typically 30 seconds)
- `status` - `ACTIVE`, `EXPIRED`, `EXECUTED`

**Usage Example:**
```ruby
# Create a quote
quote = Airwallex::Quote.create(
  from_currency: 'USD',
  to_currency: 'EUR',
  sell_amount: 1000.00
)

# Use quote for conversion before expiration
conversion = Airwallex::Conversion.create(
  quote_id: quote.id
)
```

**Critical Implementation Details:**
- Quotes expire quickly (30-60 seconds)
- Must handle `quote_expired` error
- Should expose expires_at clearly
- Consider auto-refresh logic for UX

**Testing Requirements:**
- Create quote with sell_amount
- Create quote with buy_amount
- Retrieve quote
- Handle expired quote error
- Test quote_expired exception type

---

#### 5.3. Conversion Resource

**Endpoint:** `/api/v1/conversions`  
**Purpose:** Execute currency conversions

**Operations:**
- `create` - Execute conversion (with or without quote)
- `retrieve` - Get conversion details
- `list` - List conversion history

**Key Fields:**
- `id` - Conversion ID
- `quote_id` - Optional locked quote
- `from_currency`, `to_currency`
- `sell_amount`, `buy_amount`
- `rate` - Applied rate
- `status` - `PENDING`, `COMPLETED`, `FAILED`
- `request_id` - For idempotency

**Usage Example:**
```ruby
# With quote (locked rate)
conversion = Airwallex::Conversion.create(
  quote_id: quote.id,
  request_id: "conv_#{Time.now.to_i}"
)

# Without quote (market rate)
conversion = Airwallex::Conversion.create(
  from_currency: 'USD',
  to_currency: 'EUR',
  sell_amount: 500.00,
  request_id: "conv_#{Time.now.to_i}"
)

# List conversions
conversions = Airwallex::Conversion.list(
  from_currency: 'USD',
  status: 'COMPLETED'
)
```

**Error Scenarios:**
- `quote_expired` - Quote no longer valid
- `insufficient_fund` - Not enough balance
- `rate_changed` - Market rate moved significantly
- `invalid_currency_pair` - Unsupported pair

**Testing Requirements:**
- Create with quote_id
- Create without quote (market rate)
- Retrieve conversion
- List conversions with filters
- Handle quote_expired error
- Handle insufficient_fund error
- Test idempotency

---

#### 5.4. Balance Resource

**Endpoint:** `/api/v1/balances`  
**Purpose:** Query account balances

**Operations:**
- `list` - Get balances across all currencies
- `retrieve` - Get balance for specific currency

**Key Fields:**
- `currency` - Currency code
- `available_amount` - Available for use
- `pending_amount` - In processing
- `reserved_amount` - Held (disputes, etc.)
- `total_amount` - Total balance

**Usage Example:**
```ruby
# Get all balances
balances = Airwallex::Balance.list

balances.each do |balance|
  puts "#{balance.currency}: #{balance.available_amount}"
end

# Get specific currency balance
usd_balance = Airwallex::Balance.retrieve('USD')
puts "Available: #{usd_balance.available_amount}"
puts "Pending: #{usd_balance.pending_amount}"
```

**Security Consideration:**
- May require SCA (Strong Customer Authentication) for historical data
- Should handle SCA requirement gracefully
- Add `Airwallex::SCARequiredError` exception

**Testing Requirements:**
- List all balances
- Retrieve specific currency
- Handle SCA requirement
- Test empty balances
- Verify amount calculations

---

### Implementation Plan

**Phase 1: Rates & Quotes (2-3 hours)**
1. Implement Rate resource
2. Implement Quote resource
3. Add rate/quote tests (15-20 tests)
4. Handle quote expiration

**Phase 2: Conversions (2-3 hours)**
1. Implement Conversion resource
2. Add conversion tests (15-20 tests)
3. Test with/without quotes
4. Error handling

**Phase 3: Balances (2 hours)**
1. Implement Balance resource
2. Add balance tests (10 tests)
3. SCA error handling
4. Documentation

**Total New Tests:** ~40-50 (bringing total to ~285-290)

### Documentation Updates

**README.md:**
- Add "Foreign Exchange" section
- Add "Checking Balances" section
- Update API coverage

**CHANGELOG.md:**
```markdown
### Added
- Rate resource (retrieve, list) for real-time exchange rates
- Quote resource (create, retrieve) for locked FX rates
- Conversion resource (create, retrieve, list) for currency exchange
- Balance resource (list, retrieve) for account balance queries
- 45 new tests (285 total)
```

---

## Sprint 6: Subscription & Billing

**Priority:** HIGH  
**Estimated Effort:** 8-10 hours  
**Business Value:** Recurring revenue management

### Objectives

Enable recurring payment scenarios:
1. Create and manage subscription plans
2. Subscribe customers to plans
3. Handle recurring billing cycles
4. Manage subscription lifecycle
5. Handle payment failures and retries

### Resources to Implement

#### 6.1. Plan Resource

**Endpoint:** `/api/v1/plans`  
**Purpose:** Define subscription pricing models

**Operations:**
- `create` - Create pricing plan
- `retrieve` - Get plan details
- `list` - List all plans
- `update` - Modify plan (affects new subscriptions only)
- `delete` - Deactivate plan

**Key Fields:**
- `id` - Plan ID
- `name` - Plan name
- `amount` - Price per interval
- `currency` - Pricing currency
- `interval` - `day`, `week`, `month`, `year`
- `interval_count` - Billing frequency (e.g., every 3 months)
- `trial_period_days` - Free trial length
- `metadata` - Custom data

**Usage Example:**
```ruby
# Create a monthly plan
plan = Airwallex::Plan.create(
  name: 'Pro Plan',
  amount: 49.99,
  currency: 'USD',
  interval: 'month',
  trial_period_days: 14
)

# List all active plans
plans = Airwallex::Plan.list(active: true)
```

---

#### 6.2. Subscription Resource

**Endpoint:** `/api/v1/subscriptions`  
**Purpose:** Manage customer subscriptions

**Operations:**
- `create` - Subscribe customer to plan
- `retrieve` - Get subscription details
- `list` - List subscriptions
- `update` - Modify subscription (plan change, cancel)
- `cancel` - Cancel subscription

**Key Fields:**
- `id` - Subscription ID
- `customer_id` - Customer reference
- `plan_id` - Plan reference
- `status` - `active`, `trialing`, `past_due`, `canceled`, `unpaid`
- `current_period_start` - Billing period start
- `current_period_end` - Billing period end
- `cancel_at_period_end` - Cancellation scheduled
- `payment_method_id` - Default payment method

**Custom Methods:**
- `cancel(at_period_end: true)` - Schedule cancellation
- `pause` - Pause billing
- `resume` - Resume paused subscription
- `change_plan(new_plan_id)` - Upgrade/downgrade

**Usage Example:**
```ruby
# Create subscription
sub = Airwallex::Subscription.create(
  customer_id: customer.id,
  plan_id: plan.id,
  payment_method_id: payment_method.id
)

# Cancel at period end
sub.cancel(at_period_end: true)

# Change plan (upgrade)
sub.change_plan('plan_premium')

# Pause subscription
sub.pause
```

**Webhook Events:**
- `subscription.created`
- `subscription.updated`
- `subscription.canceled`
- `subscription.trial_ending`
- `subscription.payment_failed`
- `subscription.payment_succeeded`

---

#### 6.3. Invoice Resource

**Endpoint:** `/api/v1/invoices`  
**Purpose:** View billing invoices

**Operations:**
- `retrieve` - Get invoice details
- `list` - List invoices
- `pay` - Manually pay invoice

**Key Fields:**
- `id` - Invoice ID
- `subscription_id` - Related subscription
- `amount_due` - Total amount
- `amount_paid` - Amount paid
- `status` - `draft`, `open`, `paid`, `void`, `uncollectible`
- `due_date` - Payment due date
- `period_start`, `period_end` - Billing period

**Usage Example:**
```ruby
# List customer invoices
invoices = Airwallex::Invoice.list(
  customer_id: customer.id,
  status: 'open'
)

# Pay invoice manually
invoice.pay(payment_method_id: payment_method.id)
```

---

### Testing Strategy

**Total New Tests:** ~50-60

**Coverage:**
- Plan CRUD operations (15 tests)
- Subscription lifecycle (25 tests)
- Invoice handling (15 tests)
- Payment failure scenarios (10 tests)
- Webhook event handling (5 tests)

---

## Sprint 7: Account & Identity Verification

**Priority:** MEDIUM  
**Estimated Effort:** 6-8 hours  
**Business Value:** KYC/KYB compliance

### Objectives

Enable account verification workflows:
1. Submit verification documents
2. Check verification status
3. Manage connected accounts (platform model)
4. Handle compliance requirements

### Resources to Implement

#### 7.1. VerificationDocument Resource

**Endpoint:** `/api/v1/verification_documents`  
**Purpose:** Upload KYC/KYB documents

**Operations:**
- `create` - Upload document
- `retrieve` - Get document status
- `list` - List documents

**Key Fields:**
- `id` - Document ID
- `type` - `passport`, `drivers_license`, `business_registration`
- `status` - `pending`, `verified`, `rejected`
- `rejection_reason` - If rejected
- `file_id` - Uploaded file reference

**Usage Example:**
```ruby
# Upload verification document
doc = Airwallex::VerificationDocument.create(
  type: 'passport',
  file: File.open('passport.pdf')
)

# Check status
doc = Airwallex::VerificationDocument.retrieve(doc.id)
puts doc.status # 'pending', 'verified', 'rejected'
```

---

#### 7.2. Account Resource

**Endpoint:** `/api/v1/accounts`  
**Purpose:** Manage main account and connected accounts

**Operations:**
- `retrieve` - Get account details
- `update` - Update account information
- `capabilities` - Check enabled features

**Key Fields:**
- `id` - Account ID
- `verification_status` - KYC status
- `capabilities` - Enabled features (payments, payouts, fx)
- `business_type` - Account type
- `country` - Operating country

**Usage Example:**
```ruby
# Get account info
account = Airwallex::Account.retrieve

# Check capabilities
if account.capabilities.include?('payouts')
  # Can make payouts
end

# Update account details
account.update(
  business_name: 'Updated Name',
  website: 'https://example.com'
)
```

---

#### 7.3. ConnectedAccount Resource (Platform Model)

**Endpoint:** `/api/v1/connected_accounts`  
**Purpose:** Manage sub-accounts for platforms

**Operations:**
- `create` - Onboard new merchant
- `retrieve` - Get account details
- `list` - List connected accounts
- `update` - Modify account
- `delete` - Deactivate account

**Usage Example:**
```ruby
# Create connected account
connected = Airwallex::ConnectedAccount.create(
  email: 'merchant@example.com',
  business_type: 'company',
  country: 'US'
)

# Act on behalf of connected account
Airwallex::Transfer.create(
  { amount: 100.00, beneficiary_id: 'ben_123' },
  { on_behalf_of: connected.id }
)
```

---

### Testing Strategy

**Total New Tests:** ~35-40

---

## Sprint 8: Card Issuing

**Priority:** MEDIUM-LOW  
**Estimated Effort:** 10-12 hours  
**Business Value:** Spend management

### Objectives

1. Issue virtual/physical cards
2. Manage cardholder information
3. Control spending limits
4. Handle authorization requests
5. View card transactions

### Resources to Implement

#### 8.1. Card Resource
#### 8.2. Cardholder Resource
#### 8.3. Authorization Resource
#### 8.4. CardTransaction Resource

**Note:** Card issuing is complex due to:
- PCI compliance requirements
- Remote authorization webhooks
- Real-time authorization decisions
- Card PIN handling

**Estimated Tests:** ~60-70

---

## Sprint 9: Advanced Features & Optimization

**Priority:** LOW  
**Estimated Effort:** 6-8 hours  
**Business Value:** Performance & DX improvements

### Objectives

1. **Performance Optimization**
   - Request batching
   - Connection pooling
   - Response caching (rates, balances)
   - Parallel requests

2. **Enhanced Error Handling**
   - Retry strategies per error type
   - Circuit breaker pattern
   - Error recovery suggestions

3. **Developer Experience**
   - Type hints with Sorbet/RBS
   - Better error messages
   - Request/response logging
   - Debug mode

4. **Testing Tools**
   - Fixture generators
   - Mock server for testing
   - Webhook simulator
   - Sandbox data generator

---

## Sprint 10: Enterprise Features

**Priority:** LOW  
**Estimated Effort:** 8-10 hours  
**Business Value:** Enterprise readiness

### Objectives

1. **Multi-tenant Support**
   - Thread-safe configuration
   - Multiple client instances
   - Per-request credentials

2. **Audit & Compliance**
   - Request/response logging
   - Audit trail
   - Data retention policies

3. **Advanced Authentication**
   - OAuth flows
   - JWT token support
   - Platform authentication
   - SCA handling

4. **Monitoring & Observability**
   - Metrics collection
   - APM integration (DataDog, New Relic)
   - Health checks
   - Performance tracking

---

## Release Strategy

### Option A: Frequent Releases (Recommended)

**v0.3.0** - Batch Transfers & Disputes (NOW)
- Current unreleased features
- Quick value delivery
- 240 tests

**v0.4.0** - FX & Balances (2-3 weeks)
- Sprint 5 features
- ~285 tests
- Multi-currency support

**v0.5.0** - Subscriptions & Billing (4-6 weeks)
- Sprint 6 features
- ~340 tests
- Recurring revenue

**v1.0.0** - Production Ready (8-10 weeks)
- Sprints 5-7 complete
- Enterprise features
- Full documentation
- Migration guides

### Option B: Larger Releases

**v0.3.0** - FX & Disputes Combined
- Sprints 4-5 together
- ~285 tests
- Longer dev cycle

**v0.5.0** - Full Featured
- Sprints 4-6
- ~340 tests
- Major release

---

## Technical Debt & Improvements

### High Priority

1. **Cursor Pagination Support**
   - ListObject currently defaults to offset
   - Should detect and use cursor when available
   - Some newer APIs prefer cursor

2. **Date/Time Serialization**
   - Accept Ruby Date/Time objects
   - Auto-convert to ISO 8601
   - Prevent format errors

3. **BigDecimal for Money**
   - Enforce or encourage BigDecimal
   - Prevent floating point errors
   - Documentation on money handling

4. **SCA Token Handling**
   - Add SCARequiredError
   - Document step-up auth flow
   - Provide SCA examples

### Medium Priority

5. **Request Retry Logic**
   - Smarter retry on 429
   - Exponential backoff with jitter
   - Per-resource retry config

6. **Connection Reuse**
   - Persistent HTTP connections
   - Connection pooling
   - Better performance

7. **Response Caching**
   - Cache rates for short periods
   - Cache balance queries
   - Configurable cache TTL

### Low Priority

8. **Schema Validation**
   - Use JSON Schema for validation
   - Better error messages
   - Type safety

9. **Async Support**
   - Promise-based operations
   - Background job integration
   - Webhook processing

---

## Testing Strategy Evolution

### Current: 240 tests
- Unit tests for all resources
- Integration-style tests with WebMock
- Error handling coverage
- Pagination tests

### Sprint 5: ~285 tests
- Add FX resource tests
- Rate expiration scenarios
- Quote timeout handling
- Balance edge cases

### Sprint 6: ~340 tests
- Subscription lifecycle tests
- Billing cycle tests
- Payment failure scenarios
- Webhook event tests

### Target for v1.0: ~400-450 tests
- Full resource coverage
- All edge cases
- Performance tests
- Security tests

---

## Documentation Roadmap

### Phase 1: Current (v0.2.0)
- ✅ Basic README with examples
- ✅ API coverage list
- ✅ Quick start guide
- ✅ CHANGELOG

### Phase 2: v0.3.0-0.4.0
- [ ] Detailed API reference (RDoc)
- [ ] Authentication guide
- [ ] Error handling guide
- [ ] Webhook integration guide

### Phase 3: v0.5.0-0.9.0
- [ ] Use case tutorials
- [ ] Migration guides
- [ ] Best practices
- [ ] Security guide

### Phase 4: v1.0.0
- [ ] Complete API documentation site
- [ ] Video tutorials
- [ ] Sample applications
- [ ] Integration examples

---

## Success Metrics

### Technical Metrics
- **Test Coverage:** Maintain 100% for critical paths
- **Performance:** <100ms overhead per request
- **Reliability:** 99.9% success rate in production
- **Code Quality:** 0 Rubocop offenses maintained

### Adoption Metrics
- **Downloads:** Track RubyGems downloads
- **Stars:** GitHub stars as proxy for interest
- **Issues:** Response time <48 hours
- **Contributions:** Community PR acceptance

### Business Metrics
- **Integration Time:** <4 hours for basic implementation
- **Error Rate:** <1% in production use
- **Support Tickets:** <5 per month
- **Documentation Views:** Track most-viewed pages

---

## Risk Assessment

### High Risk
1. **API Changes:** Airwallex API breaking changes
   - **Mitigation:** Pin API version, monitor changelog
   
2. **Security Vulnerabilities:** Payment data exposure
   - **Mitigation:** Security audits, dependency updates

### Medium Risk
3. **Performance Issues:** Slow requests at scale
   - **Mitigation:** Connection pooling, caching

4. **Compatibility:** Ruby version conflicts
   - **Mitigation:** Test matrix (Ruby 3.1, 3.2, 3.3)

### Low Risk
5. **Feature Bloat:** Too many features, complex API
   - **Mitigation:** Modular design, optional features

---

## Immediate Next Steps (Next 48 Hours)

### Option A: Release v0.3.0
1. ✅ Tests passing (240 tests)
2. ✅ Rubocop passing (0 offenses)
3. Update version to 0.3.0
4. Finalize CHANGELOG
5. Build gem
6. Publish to RubyGems
7. Create git tag
8. GitHub release notes

### Option B: Start Sprint 5 (FX)
1. Create Sprint 5 detailed plan
2. Implement Rate resource
3. Implement Quote resource
4. Implement Conversion resource
5. Implement Balance resource
6. Write comprehensive tests
7. Update documentation
8. Then release v0.4.0

---

## Recommendation

**Recommended Path: Release v0.3.0 NOW, then Sprint 5**

**Rationale:**
1. **Incremental Value:** Users get batch transfers & disputes immediately
2. **Feedback Loop:** Get real-world feedback before FX implementation
3. **Momentum:** Regular releases build trust and engagement
4. **Risk Mitigation:** Smaller releases = easier rollback if issues
5. **Development Focus:** Can focus on Sprint 5 with clean slate

**Timeline:**
- **Today:** Release v0.3.0 (1 hour)
- **This Week:** Start Sprint 5 planning (2 hours)
- **Next Week:** Implement Sprint 5 (6-8 hours)
- **Week After:** Release v0.4.0

---

## Long-term Vision (6-12 months)

### v1.0.0 Goals
- All major Airwallex APIs covered
- Production-grade error handling
- Comprehensive documentation
- Enterprise features (multi-tenant, audit)
- Performance optimized
- Community-driven development

### v2.0.0 Aspirations
- Async/await support
- GraphQL API support (if Airwallex adds it)
- Real-time event streaming
- Advanced caching strategies
- AI-powered error recovery
- Zero-config setup for common use cases

---

## Conclusion

The Airwallex Ruby gem has achieved significant maturity through 4 sprints. The foundation is solid, tests are comprehensive, and the code quality is excellent. 

**The recommended next step is to release v0.3.0 immediately**, delivering tangible value to users while gaining feedback for future development. Sprint 5 (FX & Balance) should follow as the natural next evolution, enabling critical multi-currency operations.

The roadmap balances **business value, technical excellence, and sustainable development pace**. Each sprint builds logically on the previous, with clear milestones and success criteria.

**Ready to proceed with v0.3.0 release?**
