# Airwallex Ruby Gem

A Ruby client library for the [Airwallex API](https://www.airwallex.com/docs/api), providing access to payment acceptance and payout capabilities.

## Overview

This gem provides a Ruby interface to Airwallex's payment infrastructure, designed for Ruby 3.1+ applications. It includes core functionality for authentication management, idempotency guarantees, webhook verification, and multi-environment support.

**Current Features:**

- **Authentication**: Bearer token authentication with automatic refresh
- **Payment Acceptance**: Payment intents, refunds, payment methods, customers, disputes
- **Payouts**: Transfers, batch transfers, and beneficiary management
- **Foreign Exchange**: Real-time rates, locked quotes, and currency conversions
- **Global Accounts**: Virtual account numbers (VANs), inbound transaction reconciliation, aliases, and direct debit mandates
- **Billing**: Products, prices, billing customers, and subscriptions for recurring/instalment billing
- **Recurring Payments**: Payment consents and payment sources for merchant-initiated (off-session) charges
- **Scale**: Connected accounts, funds splits, and charges for platforms onboarding sub-merchants
- **Sandbox Simulations**: Deposits, issuing transactions, disputes, transfer status, Direct Debit mandates, connected account/offboarding review outcomes, RFIs, and POS terminals — see [Sandbox Simulations](#sandbox-simulations)
- **Idempotency**: Automatic request deduplication for safe retries
- **Pagination**: Unified interface over cursor-based and offset-based pagination
- **Webhook Security**: HMAC-SHA256 signature verification with replay protection
- **Sandbox Support**: Full testing environment for development

**Not yet implemented:** live Card issuing resources (Card, Cardholder create/retrieve/list) — only their sandbox Simulation actions are covered today.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'airwallex'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install airwallex
```

## Quick Start

### Configuration

```ruby
require 'airwallex'

Airwallex.configure do |config|
  config.api_key = 'your_api_key'
  config.client_id = 'your_client_id'
  config.environment = :sandbox # or :production
end
```

### Creating a Payment Intent

```ruby
# Create a payment intent
payment_intent = Airwallex::PaymentIntent.create(
  amount: 100.00,
  currency: 'USD',
  merchant_order_id: 'order_123',
  return_url: 'https://yoursite.com/return'
)

# Confirm with card details
payment_intent.confirm(
  payment_method: {
    type: 'card',
    card: {
      number: '4242424242424242',
      expiry_month: '12',
      expiry_year: '2025',
      cvc: '123'
    }
  }
)
```

### Creating a Payout

```ruby
# Create a beneficiary
beneficiary = Airwallex::Beneficiary.create(
  nickname: 'Acme Corp',
  payer_entity_type: 'COMPANY',
  transfer_methods: ['LOCAL'],
  beneficiary: {
    entity_type: 'COMPANY',
    company_name: 'Acme Corp',
    address: {
      country_code: 'AU',
      city: 'Melbourne',
      state: 'VIC',
      postcode: '3000',
      street_address: '15 William Street'
    },
    bank_details: {
      account_name: 'Acme Corp',
      account_number: '12750852',
      account_currency: 'AUD',
      bank_country_code: 'AU',
      bank_name: 'National Australia Bank',
      account_routing_type1: 'bsb',
      account_routing_value1: '083064',
      local_clearing_system: 'BANK_TRANSFER'
    }
  }
)

# Execute transfer
transfer = Airwallex::Transfer.create(
  beneficiary_id: beneficiary.id,
  source_currency: 'USD',
  transfer_method: 'LOCAL',
  amount: 1000.00,
  reason: 'Payment for services'
)
```

### Processing Refunds

```ruby
# Create a full refund
refund = Airwallex::Refund.create(
  payment_intent_id: payment_intent.id,
  amount: 100.00,
  reason: 'requested_by_customer'
)

# Create a partial refund
partial_refund = Airwallex::Refund.create(
  payment_intent_id: payment_intent.id,
  amount: 50.00
)

# List all refunds for a payment
refunds = Airwallex::Refund.list(payment_intent_id: payment_intent.id)
```

### Managing Payment Methods

```ruby
# Create a customer
customer = Airwallex::Customer.create(
  merchant_customer_id: 'internal_customer_001',
  email: 'customer@example.com',
  first_name: 'John',
  last_name: 'Doe'
)

# Save a payment method
payment_method = Airwallex::PaymentMethod.create(
  type: 'card',
  card: {
    number: '4242424242424242',
    expiry_month: '12',
    expiry_year: '2025',
    cvc: '123'
  },
  billing: {
    first_name: 'John',
    email: 'customer@example.com'
  }
)

# Use saved payment method
payment_intent.confirm(payment_method_id: payment_method.id)

# List customer's payment methods
methods = customer.payment_methods

# Disable a payment method (PaymentMethods have no delete/detach endpoint)
payment_method.disable
```

### Batch Transfers

```ruby
# Create a batch of transfers for bulk payouts
batch = Airwallex::BatchTransfer.create(
  request_id: "batch_#{Time.now.to_i}",
  source_currency: 'USD',
  transfers: [
    { beneficiary_id: 'ben_001', amount: 100.00, reason: 'Seller payout' },
    { beneficiary_id: 'ben_002', amount: 250.00, reason: 'Affiliate payment' },
    { beneficiary_id: 'ben_003', amount: 500.00, reason: 'Vendor payment' }
  ]
)

# Check batch status
batch = Airwallex::BatchTransfer.retrieve(batch.id)
puts "Completed: #{batch.success_count}/#{batch.total_count}"

# Check individual transfer statuses
batch.transfers.each do |transfer|
  puts "#{transfer.id}: #{transfer.status}"
end
```

### Managing Disputes

```ruby
# List all open disputes
disputes = Airwallex::Dispute.list(status: 'OPEN')

# Get specific dispute
dispute = Airwallex::Dispute.retrieve('dis_123')
puts "Dispute amount: #{dispute.amount} #{dispute.currency}"
puts "Reason: #{dispute.reason}"
puts "Evidence due: #{dispute.evidence_due_by}"

# Challenge the dispute with evidence
dispute.challenge(
  customer_communication: 'Email showing delivery confirmation',
  shipping_tracking_number: '1Z999AA10123456784',
  shipping_documentation: 'Proof of delivery with signature'
)

# Or accept dispute without challenging
dispute.accept

# List the payment intents related to a dispute
dispute.related_payment_intents
```

### Foreign Exchange & Multi-Currency

```ruby
# Get real-time exchange rate
rate = Airwallex::Rate.retrieve(
  buy_currency: 'EUR',
  sell_currency: 'USD'
)
puts "Current rate: #{rate.client_rate}"

# Lock in a rate with a quote (valid for 24 hours)
quote = Airwallex::Quote.create(
  buy_currency: 'EUR',
  sell_currency: 'USD',
  sell_amount: 10000.00,
  validity: 'HR_24'
)

puts "Locked rate: #{quote.client_rate}"
puts "Expires in: #{quote.seconds_until_expiration} seconds"
puts "Is expired? #{quote.expired?}"

# Execute conversion using locked quote
conversion = Airwallex::Conversion.create(
  quote_id: quote.id,
  reason: 'Multi-currency settlement'
)

# Or convert at current market rate
conversion = Airwallex::Conversion.create(
  buy_currency: 'EUR',
  sell_currency: 'USD',
  sell_amount: 5000.00,
  reason: 'Currency exchange'
)

# Check account balances
balances = Airwallex::Balance.list
balances.each do |balance|
  next if balance.available_amount <= 0
  puts "#{balance.currency}: #{balance.available_amount} available"
end

# Get specific currency balance
usd_balance = Airwallex::Balance.retrieve('USD')
puts "USD Available: #{usd_balance.available_amount}"
puts "USD Total: #{usd_balance.total_amount}"
```

### Global Accounts (Virtual Account Numbers)

```ruby
# Provision a VAN
account = Airwallex::GlobalAccount.create(
  country_code: 'AU',
  nick_name: 'booking_12345',
  required_features: [{ transfer_method: 'LOCAL' }]
)

# List inbound transactions for reconciliation
account.transactions.each { |txn| puts "#{txn.amount} from #{txn.remitter}" }

# Add and verify an alias (e.g. a phone number or email VAN)
alias_record = account.create_alias(type: 'PAYID_PHONE', value: '+61400000000')
alias_record.submit_verification_code(code: '123456')
account.aliases

# Manage direct debit mandates
account.mandates
mandate = account.mandate('mandate_id')
mandate.cancel
```

### Billing & Subscriptions

```ruby
# Create a billing customer
billing_customer = Airwallex::BillingCustomer.create(
  name: 'Acme Corp',
  email: 'billing@acme.com',
  type: 'BUSINESS',
  default_billing_currency: 'AUD',
  default_legal_entity_id: connected_account.legal_entity_id,
  address: {
    street: '15 William Street',
    city: 'Melbourne',
    state: 'VIC',
    postcode: '3000',
    country_code: 'AU'
  }
)

# Define a product and a recurring price
product = Airwallex::BillingProduct.create(name: 'Pro Plan')
price = Airwallex::BillingPrice.create(
  product_id: product.id,
  currency: 'AUD',
  unit_amount: 99.00,
  pricing_model: 'PER_UNIT',
  recurring: { period: 1, period_unit: 'MONTH' }
)

# Subscriptions bill against a PaymentSource, not a PaymentConsent directly
# (see "Recurring Payments" below for how to obtain one)
subscription = Airwallex::BillingSubscription.create(
  billing_customer_id: billing_customer.id,
  currency: 'AUD',
  collection_method: 'AUTO_CHARGE',
  legal_entity_id: connected_account.legal_entity_id,
  payment_source_id: payment_source.id,
  starts_at: '2026-09-01T00:00:00+1000',
  items: [{ price_id: price.id, quantity: 1 }]
)

# Inspect subscription line items
subscription.items
```

### Recurring Payments (Payment Consents & Sources)

Off-session charges flow through three linked resources: a `PaymentMethod` is
consented to future charges via a `PaymentConsent`, which then backs a
`PaymentSource` that `BillingSubscription` (and other billing resources) can
charge automatically.

```ruby
# Consent to future merchant-initiated charges on a saved payment method
consent = Airwallex::PaymentConsent.create(
  customer_id: customer.id,
  payment_method: { id: payment_method.id },
  next_triggered_by: 'merchant',
  merchant_trigger_reason: 'unscheduled'
)
consent.verify(payment_method: { card: { cvc: '123' } })

# Wrap the consented payment method as a Payment Source for Billing
# external_id is the PaymentMethod's id, not the PaymentConsent's id
payment_source = Airwallex::PaymentSource.create(
  billing_customer_id: billing_customer.id,
  external_id: payment_method.id,
  linked_payment_account_id: connected_account.id
)
```

### Scale (Connected Accounts, Funds Splits, Charges)

For platforms onboarding sub-merchants:

```ruby
# Onboard a connected account
# account_details is a required top-level wrapper; nickname/primary_contact/
# customer_agreements are top-level siblings, not nested inside it.
connected_account = Airwallex::ConnectedAccount.create(
  nickname: 'Sub-merchant Co',
  primary_contact: { email: 'contact@submerchant.com' },
  customer_agreements: {
    agreed_to_terms_and_conditions: true,
    agreed_to_data_usage: true,
    terms_and_conditions: { service_agreement_type: 'FULL' }
  },
  account_details: {
    legal_entity_type: 'BUSINESS',
    business_details: {
      business_name: 'Sub-merchant Co',
      business_structure: 'COMPANY'
    }
  }
)
connected_account.legal_entity_id
connected_account.agree_to_terms_and_conditions
connected_account.submit

# Inspect the platform's own account
Airwallex::ConnectedAccount.current
Airwallex::ConnectedAccount.wallet_info

# Split a charge's funds between the platform and a connected account
split = Airwallex::FundsSplit.create(
  payment_intent_id: payment_intent.id,
  splits: [{ account_id: connected_account.id, amount: 10.00 }]
)
split.release

# Charges (create, retrieve, list)
charge = Airwallex::Charge.retrieve('charge_id')
```

### Sandbox Simulations

Sandbox-only endpoints (`/api/v1/simulation/...`) that stand in for the bank,
card network, issuing bank, or shopper — for driving async/manual lifecycles
in tests without waiting on real-world events. See
https://www.airwallex.com/docs/api/simulation/ for the full reference. All
of these raise `Airwallex::Error` (same as any other endpoint) if called
against a production API key.

#### Deposits

```ruby
# Simulate an inbound bank transfer landing in a Global Account — auto-settles
# on its own within a few seconds, same as a real bank transfer
Airwallex::Deposit.simulate_create(amount: 100.00, global_account_id: 'gacc_123')

# .simulate_settle/.simulate_reject/.simulate_reverse are for Direct Debit
# deposits specifically, made via the real (non-simulation) .create — a real
# direct debit pull takes days to clear, so the sandbox needs a way to force it
pending = Airwallex::Deposit.create(funding_source_id: 'la_123', amount: 50.00, currency: 'AUD')
pending.simulate_settle # -> SETTLED
# or: pending.simulate_reject -> REJECTED

# Reversing only works on an already-SETTLED Direct Debit deposit; it creates
# an offsetting settled deposit and deactivates the LinkedAccount
settled = Airwallex::Deposit.create(funding_source_id: 'la_123', amount: 50.00, currency: 'AUD')
settled.simulate_settle
settled.simulate_reverse

# Class-level equivalents take a deposit_id directly instead of an instance
Airwallex::Deposit.simulate_settle('dpt_123')
Airwallex::Deposit.simulate_reject('dpt_123')
Airwallex::Deposit.simulate_reverse('dpt_123')
```

#### Issuing Transactions

```ruby
# Authorize, then capture in full
txn = Airwallex::IssuingTransaction.simulate_create(
  card_id: 'card_123',
  transaction_amount: 25.00,
  transaction_currency: 'USD'
)
Airwallex::IssuingTransaction.simulate_capture(txn.transaction_id)

# Authorize, then capture only part of the authorized amount
txn = Airwallex::IssuingTransaction.simulate_create(
  card_id: 'card_123', transaction_amount: 25.00, transaction_currency: 'USD'
)
Airwallex::IssuingTransaction.simulate_capture(txn.transaction_id, transaction_amount: 10.00)

# Authorize and clear in a single step (no separate capture needed)
Airwallex::IssuingTransaction.simulate_create(
  card_id: 'card_123', transaction_amount: 25.00, transaction_currency: 'USD', single_phase: true
)

# Reverse a still-PENDING (uncaptured) authorization instead of capturing it
txn = Airwallex::IssuingTransaction.simulate_create(
  card_id: 'card_123', transaction_amount: 25.00, transaction_currency: 'USD'
)
Airwallex::IssuingTransaction.simulate_reverse(txn.transaction_id)

# Refund a CAPTURED transaction back to the card
Airwallex::IssuingTransaction.simulate_refund(
  card_id: 'card_123', transaction_amount: 25.00, transaction_currency: 'USD'
)

# Simulate a 3DS delegation-mode notification for a card
Airwallex::IssuingTransaction.simulate_notify_three_ds(card_number: '4111111111111111')
```

#### Disputes

```ruby
# Full lifecycle: raised, challenged, then resolved in the merchant's favor
dispute = Airwallex::Dispute.simulate_create(
  payment_intent_id: payment_intent.id,
  reason_code: '4853',
  stage: 'CHARGEBACK',
  due_at: (Time.now + 86_400).iso8601
)
dispute.challenge(customer_communication: 'Proof of delivery')
dispute.simulate_resolve(in_favor_of: 'MERCHANT')

# Or accept without challenging, then resolve in the customer's favor
dispute = Airwallex::Dispute.simulate_create(
  payment_intent_id: payment_intent.id, reason_code: '4853', stage: 'CHARGEBACK',
  due_at: (Time.now + 86_400).iso8601
)
dispute.accept
dispute.simulate_resolve(in_favor_of: 'CUSTOMER')

# Escalate — the issuing bank rejects the challenge evidence and advances the
# dispute to the next stage (e.g. Chargeback -> Pre-arbitration)
dispute.challenge(customer_communication: 'Proof of delivery')
dispute.simulate_escalate(due_at: (Time.now + 86_400).iso8601)

# Class-level equivalents take a dispute_id directly instead of an instance
Airwallex::Dispute.simulate_escalate('dis_123', due_at: (Time.now + 86_400).iso8601)
Airwallex::Dispute.simulate_resolve('dis_123', in_favor_of: 'MERCHANT')
```

#### Transfers

```ruby
# Advance a transfer's status one step at a time: SCHEDULED -> PROCESSING ->
# SENT -> PAID
transfer.simulate_transition(next_status: 'PROCESSING')
transfer.simulate_transition(next_status: 'SENT')
transfer.simulate_transition(next_status: 'PAID')

# OVERDUE, FAILED, and CANCELLED can be jumped to directly
transfer.simulate_transition(next_status: 'FAILED', failure_type: 'INSUFFICIENT_FUNDS')

# Class-level equivalent takes a transfer_id directly instead of an instance
Airwallex::Transfer.simulate_transition('tfr_123', next_status: 'CANCELLED')
```

#### Connected Accounts & Offboarding

```ruby
# Simulate a KYC/KYB review outcome (account must currently be SUBMITTED)
connected_account.simulate_update_status(next_status: 'ACTIVE')
# or: connected_account.simulate_update_status(next_status: 'SUSPENDED')
# or: connected_account.simulate_update_status(next_status: 'ACTION_REQUIRED')

# Class-level equivalent takes an account_id directly instead of an instance
Airwallex::ConnectedAccount.simulate_update_status('acct_123', next_status: 'ACTIVE')

# Simulate a pending offboarding completing or being cancelled — via the
# parent ConnectedAccount instance...
connected_account.simulate_complete_offboarding('obd_456')
connected_account.simulate_cancel_offboarding('obd_456')

# ...or directly against AccountOffboarding with both ids
Airwallex::AccountOffboarding.simulate_complete('acct_123', 'obd_456')
Airwallex::AccountOffboarding.simulate_cancel('acct_123', 'obd_456')
```

#### Account Amendments

```ruby
amendment = Airwallex::AccountAmendment.create(
  target: 'account_details.store_details',
  store_details: { store_name: 'New Store Name' }
)
amendment.simulate_approve
# or: amendment.simulate_reject

# Class-level equivalents take an amendment_id directly instead of an instance
Airwallex::AccountAmendment.simulate_approve('amd_123')
Airwallex::AccountAmendment.simulate_reject('amd_123')
```

#### Linked Accounts (Direct Debit Mandates)

```ruby
# Mandate lifecycle: PROCESSING -> ACTIVE, or PROCESSING -> INACTIVE. All
# four actions return HTTP 200 with an empty body, so the gem returns `true`
# rather than a resource instance.
Airwallex::LinkedAccount.simulate_accept_mandate('la_123')  # PROCESSING -> ACTIVE
Airwallex::LinkedAccount.simulate_reject_mandate('la_123')  # PROCESSING -> INACTIVE
Airwallex::LinkedAccount.simulate_cancel_mandate('la_123')  # PROCESSING or ACTIVE -> INACTIVE

# Simulate a failed micro-deposit verification: REQUIRES_ACTION -> FAILED
Airwallex::LinkedAccount.simulate_fail_microdeposits('la_123')
```

#### Shopper Actions

```ruby
# Simulate the shopper completing (or abandoning) a redirect/3DS challenge
# raised during PaymentIntent#confirm, using the url from its next_action
payment_intent.simulate_shopper_pay(url: next_action_url)
# or: payment_intent.simulate_shopper_reject(url: next_action_url)

# Simulate the shopper completing a redirect/3DS challenge raised during
# PaymentConsent#verify, using the url from its next_action
payment_consent.simulate_shopper_verify(url: next_action_url)
```

#### Issuing Cardholders

```ruby
# Bypass a cardholder's pending RFI review stage
Airwallex::Cardholder.simulate_pass_review('chd_123')
```

#### Requests for Information (RFIs)

```ruby
# Raise a KYC RFI, then close it
rfi = Airwallex::RFI.simulate_create(type: 'KYC', questions: [{ answer: { type: 'TEXT' } }])
rfi.simulate_close

# Follow up on an RFI — reopen an existing answered question (by id) or
# append a new one
rfi = Airwallex::RFI.simulate_create(type: 'KYC', questions: [{ answer: { type: 'TEXT' } }])
rfi.simulate_follow_up(questions: [{ answer: { type: 'TEXT' } }])

# Class-level equivalents take an rfi_id directly instead of an instance
Airwallex::RFI.simulate_close('rfi_123')
Airwallex::RFI.simulate_follow_up('rfi_123', questions: [{ answer: { type: 'TEXT' } }])
```

#### POS Terminals

```ruby
# Turn a terminal on, then have it confirm a PaymentIntent under a named test
# scenario
Airwallex::POSTerminal.simulate_turn_on(terminal_id: 'term_123')
Airwallex::POSTerminal.simulate_confirm_payment_intent(
  terminal_id: 'term_123', payment_scenario_name: 'approve'
)
Airwallex::POSTerminal.simulate_turn_off(terminal_id: 'term_123')

# List the test scenario names available to simulate_confirm_payment_intent
Airwallex::POSTerminal.simulate_payment_scenarios

# Generate a terminal activation code
Airwallex::POSTerminal.simulate_generate_activation_code(request_id: 'req_123')
```

## Usage

### Authentication

The gem uses Bearer token authentication with automatic token refresh:

```ruby
Airwallex.configure do |config|
  config.api_key = 'your_api_key'
  config.client_id = 'your_client_id'
  config.environment = :sandbox # or :production
end
```

Tokens are automatically refreshed when they expire, and the gem handles thread-safe token management.

### Idempotency

The gem automatically handles idempotency for safe retries:

```ruby
# Automatic request_id generation
transfer = Airwallex::Transfer.create(
  amount: 500.00,
  beneficiary_id: 'ben_123'
  # request_id automatically generated
)

# Or provide your own for reconciliation
transfer = Airwallex::Transfer.create(
  amount: 500.00,
  beneficiary_id: 'ben_123',
  request_id: 'my_internal_id_789'
)
```

### Pagination

Unified interface across both cursor-based and offset-based endpoints:

```ruby
# Auto-pagination with enumerable
Airwallex::Transfer.list.auto_paging_each do |transfer|
  puts transfer.id
end

# Manual pagination
transfers = Airwallex::Transfer.list(page_size: 50)
while transfers.has_more?
  transfers.each { |t| process(t) }
  transfers = transfers.next_page
end
```

### Webhook Handling

```ruby
# In your webhook controller
payload = request.body.read
signature = request.headers['x-signature']
timestamp = request.headers['x-timestamp']

begin
  event = Airwallex::Webhook.construct_event(
    payload,
    signature,
    timestamp,
    tolerance: 300 # 5 minutes
  )

  case event.name
  when 'payment_intent.succeeded'
    handle_successful_payment(event.data)
  when 'payout.transfer.failed'
    handle_failed_payout(event.data)
  end
rescue Airwallex::SignatureVerificationError => e
  # Invalid signature
  head :bad_request
end
```

### Error Handling

```ruby
begin
  transfer = Airwallex::Transfer.create(params)
rescue Airwallex::InsufficientFundsError => e
  # Handle insufficient balance
  notify_user("Insufficient funds: #{e.message}")
rescue Airwallex::RateLimitError => e
  # Rate limit hit - automatic retry with backoff
  retry_with_backoff
rescue Airwallex::AuthenticationError => e
  # Invalid credentials
  log_error("Auth failed: #{e.message}")
rescue Airwallex::APIError => e
  # General API error
  log_error("API error: #{e.code} - #{e.message}")
end
```

## Architecture

### Design Principles

- **Correctness First**: Automatic idempotency and type safety prevent duplicate transactions
- **Fail-Safe Defaults**: Sandbox environment default, automatic token refresh
- **Developer Experience**: Auto-pagination, dynamic schema validation, structured errors
- **Security**: HMAC webhook verification, constant-time signature comparison, SCA support
- **Resilience**: Exponential backoff, jittered retries, concurrent request limits

### Core Components

```
lib/airwallex/
├── api_operations/        # CRUD operation mixins (Create, Retrieve, List, Update, Delete)
├── resources/             # Implemented resources, grouped by API area:
│   │                      #   payment acceptance    - payment_intent, refund, payment_method, customer, dispute
│   │                      #   payouts                - transfer, batch_transfer, beneficiary
│   │                      #   foreign exchange        - rate, quote, conversion, balance
│   │                      #   global accounts         - global_account(+_alias, _mandate, _transaction)
│   │                      #   billing                 - billing_customer, billing_product, billing_price,
│   │                      #                             billing_subscription(+_item)
│   │                      #   recurring payments      - payment_consent, payment_source
│   │                      #   scale                   - connected_account, account_amendment, funds_split, charge
│   └── ...                # see lib/airwallex/resources/ for the full, current list
├── api_resource.rb        # Base resource class with dynamic attributes
├── list_object.rb         # Pagination wrapper
├── errors.rb              # Exception hierarchy
├── client.rb              # HTTP client with authentication
├── configuration.rb       # Environment and credentials
├── webhook.rb             # Signature verification
├── util.rb                # Helper methods
└── middleware/            # Faraday middleware
    └── idempotency.rb     # Automatic request_id injection
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

### Running Tests

```bash
bundle exec rspec
```

### Code Style

```bash
bundle exec rubocop
```

### Local Development

```ruby
# In bin/console or irb
require 'airwallex'

Airwallex.configure do |config|
  config.environment = :sandbox
  config.api_key = ENV['AIRWALLEX_API_KEY']
  config.client_id = ENV['AIRWALLEX_CLIENT_ID']
end
```

## API Coverage

### Currently Implemented Resources

- **Payment Acceptance**:
  - PaymentIntent (create, retrieve, list, update, confirm, cancel, capture, simulate_shopper_pay, simulate_shopper_reject)
  - Refund (create, retrieve, list)
  - PaymentMethod (create, retrieve, list, update, disable)
  - Customer (create, retrieve, list, update, delete)
  - Dispute (retrieve, list, accept, challenge, related_payment_intents, simulate_create, simulate_escalate, simulate_resolve)
- **Payouts**:
  - Transfer (create, retrieve, list, cancel, simulate_transition)
  - Beneficiary (create, retrieve, list, update, delete, validate, verify_account, api_schema, form_schema, supported_financial_institutions)
  - BatchTransfer (create, retrieve, list)
- **Foreign Exchange & Multi-Currency**:
  - Rate (retrieve) - Real-time exchange rate queries
  - Quote (create, retrieve) - Lock exchange rates with expiration tracking
  - Conversion (create, retrieve, list) - Execute currency conversions
  - Balance (list, retrieve) - Query account balances across currencies
- **Global Accounts**:
  - GlobalAccount (create, retrieve, list, update, close, generate_statement_letter, create_alias, aliases, mandate, mandates)
  - GlobalAccountTransaction, GlobalAccountAlias, GlobalAccountMandate (list/lifecycle actions scoped to a parent account)
  - Deposit (create, retrieve, list — Direct Debit only; simulate_create for a Global Account bank-transfer deposit, simulate_settle/simulate_reject/simulate_reverse for Direct Debit deposits made via create)
  - LinkedAccount — sandbox Simulation only (simulate_accept_mandate, simulate_reject_mandate, simulate_cancel_mandate, simulate_fail_microdeposits)
- **Billing & Subscriptions**:
  - BillingCustomer (create, retrieve, list, update, bank_transfer_instructions)
  - BillingProduct (create, retrieve, list, update)
  - BillingPrice (create, retrieve, list, update)
  - BillingSubscription (create, retrieve, list, update, items)
  - BillingSubscriptionItem (scoped to a parent subscription)
- **Recurring Payments**:
  - PaymentConsent (create, retrieve, list, update, verify, verify_continue, disable, simulate_shopper_verify)
  - PaymentSource (create, retrieve, list)
- **Scale**:
  - ConnectedAccount (create, retrieve, list, update, current, wallet_info, submit, agree_to_terms_and_conditions, suspend, reactivate, simulate_update_status, simulate_complete_offboarding, simulate_cancel_offboarding)
  - AccountAmendment (create, retrieve, simulate_approve, simulate_reject) - requires Admin-level API key permissions
  - AccountOffboarding — sandbox Simulation only, scoped to a parent ConnectedAccount (simulate_complete, simulate_cancel)
  - FundsSplit (create, retrieve, list, release)
  - Charge (create, retrieve, list)
- **Issuing** (sandbox Simulation only — no live Card/Cardholder resources yet):
  - IssuingTransaction (simulate_create with single_phase, simulate_capture, simulate_reverse, simulate_refund, simulate_notify_three_ds)
  - Cardholder (simulate_pass_review)
- **In-Person Payments** (sandbox Simulation only):
  - POSTerminal (simulate_turn_on, simulate_turn_off, simulate_generate_activation_code, simulate_confirm_payment_intent, simulate_payment_scenarios)
- **Compliance** (sandbox Simulation only):
  - RFI (simulate_create, simulate_close, simulate_follow_up)
- **Webhooks**: Event handling, HMAC-SHA256 signature verification

### Coming in Future Versions

- Live Card issuing resources (Card, Cardholder create/retrieve/list) — only their sandbox Simulation actions are implemented today

## Environment Support

### Sandbox

Testing environment for development:

```ruby
Airwallex.configure do |config|
  config.environment = :sandbox
  config.api_key = ENV['AIRWALLEX_SANDBOX_API_KEY']
  config.client_id = ENV['AIRWALLEX_SANDBOX_CLIENT_ID']
end
```

### Production

Live environment for real financial transactions:

```ruby
Airwallex.configure do |config|
  config.environment = :production
  config.api_key = ENV['AIRWALLEX_API_KEY']
  config.client_id = ENV['AIRWALLEX_CLIENT_ID']
end
```

## Rate Limits

The gem respects Airwallex API rate limits. If you encounter `Airwallex::RateLimitError`, implement retry logic with exponential backoff:

```ruby
begin
  transfer = Airwallex::Transfer.create(params)
rescue Airwallex::RateLimitError => e
  sleep(2 ** retry_count)
  retry_count += 1
  retry if retry_count < 3
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/Sentia/airwallex>.

### Development Setup

1. Fork and clone the repository
2. Run `bin/setup` to install dependencies
3. Create a `.env` file with sandbox credentials
4. Run tests: `bundle exec rspec`
5. Check style: `bundle exec rubocop`

### Guidelines

- Write tests for new features
- Follow existing code style (enforced by Rubocop)
- Update documentation for API changes
- Ensure all tests pass before submitting PR

## Versioning

This gem follows [Semantic Versioning](https://semver.org/). The Airwallex API uses date-based versioning, which is handled internally by the gem.

## Security

If you discover a security vulnerability, please email security@sentia.com instead of using the issue tracker.

## Documentation

- [Airwallex API Documentation](https://www.airwallex.com/docs/api)
- [API Reference](https://www.airwallex.com/docs/api#overview)

## Requirements

- Ruby 3.1 or higher
- Bundler 2.0 or higher

## Dependencies

- `faraday` (~> 2.0) - HTTP client
- `faraday-retry` - Request retry logic
- `faraday-multipart` - File upload support

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Support

- GitHub Issues: <https://github.com/Sentia/airwallex/issues>
- Airwallex Support: <https://www.airwallex.com/support>

## Acknowledgments

Built with comprehensive analysis of the Airwallex API ecosystem. Special thanks to the Airwallex team for their extensive documentation and developer resources.
