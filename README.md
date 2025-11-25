# Airwallex Ruby Gem

A production-grade Ruby client library for the [Airwallex API](https://www.airwallex.com/docs/api), providing comprehensive access to global payment acceptance, payouts, foreign exchange, card issuing, and treasury management capabilities.

## Overview

This gem implements a robust, type-safe interface to Airwallex's financial infrastructure, designed for Ruby 3.1+ applications. It handles the complexities of distributed financial systems including authentication lifecycle management, idempotency guarantees, webhook verification, and multi-environment support.

**Key Features:**

- **Multi-layered Authentication**: Supports Bearer tokens, OAuth flows, and SCA (Strong Customer Authentication)
- **Payment Acceptance**: Cards, digital wallets (Apple Pay, Google Pay), and 100+ local payment methods
- **Global Payouts**: Local and SWIFT transfers with dynamic schema validation for 50+ countries
- **Foreign Exchange**: Real-time rates, locked quotes, and automatic conversion
- **Card Issuing**: Virtual and physical card creation with real-time authorization controls
- **Global Accounts**: Multi-currency virtual IBANs for local collections
- **Idempotency**: Automatic request deduplication for safe retries
- **Auto-pagination**: Unified interface over cursor-based and offset-based pagination
- **Webhook Security**: HMAC-SHA256 signature verification with replay protection
- **Sandbox Support**: Full testing environment with magic values for edge cases

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
  bank_details: {
    account_number: '123456789',
    account_routing_type1: 'aba',
    account_routing_value1: '026009593',
    bank_country_code: 'US'
  },
  beneficiary_type: 'BUSINESS',
  company_name: 'Acme Corp'
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

### Foreign Exchange

```ruby
# Get current rate
rate = Airwallex::FX.rate(
  buy_currency: 'EUR',
  sell_currency: 'USD'
)

# Lock a quote
quote = Airwallex::FX::Quote.create(
  buy_currency: 'EUR',
  sell_currency: 'USD',
  sell_amount: 10000.00
)

# Execute conversion with locked rate
conversion = Airwallex::FX::Conversion.create(
  quote_id: quote.id
)
```

## Usage

### Authentication

The gem supports multiple authentication strategies:

#### Direct Merchant (Bearer Token)
```ruby
Airwallex.configure do |config|
  config.api_key = 'your_api_key'
  config.client_id = 'your_client_id'
end
```

#### Platform/Connected Accounts (OAuth)
```ruby
client = Airwallex::Client.new(
  access_token: 'oauth_access_token',
  refresh_token: 'oauth_refresh_token'
)

# Act on behalf of connected account
client.headers['x-on-behalf-of'] = 'acct_connected_123'
```

#### Scoped API Keys
```ruby
# Use scoped keys for least-privilege access
Airwallex.configure do |config|
  config.api_key = 'scoped_key_with_limited_permissions'
  config.client_id = 'your_client_id'
end
```

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
  
  case event.type
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
├── api_operations/     # CRUD operation mixins
├── resources/          # Domain models (Payment, Transfer, etc.)
├── errors.rb           # Exception hierarchy
├── client.rb           # HTTP client and configuration
├── webhook.rb          # Signature verification
├── util.rb             # Pagination, time formatting
└── middleware/         # Faraday middleware
    ├── auth_refresh.rb # Token lifecycle management
    └── idempotency.rb  # Automatic request_id injection
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

### Supported Resources

- **Payment Acceptance**: PaymentIntents, PaymentMethods, Refunds
- **Payouts**: Transfers, Beneficiaries, Batch Transfers
- **Foreign Exchange**: Rates, Quotes, Conversions
- **Global Accounts**: Account creation, transactions, multi-currency
- **Card Issuing**: Card creation, authorization, spend controls
- **Connected Accounts**: Account management, KYC/KYB flows
- **Webhooks**: Event handling, signature verification

## Environment Support

### Sandbox

Full testing environment with simulated banking networks:

```ruby
Airwallex.configure do |config|
  config.environment = :sandbox
end
```

**Magic Values for Testing:**

- Amount `$88.88` triggers 3D Secure challenges
- Specific card numbers simulate various decline scenarios
- Simulation endpoints force state transitions

### Production

Live environment for real financial transactions:

```ruby
Airwallex.configure do |config|
  config.environment = :production
  # Requires separate production credentials
end
```

## Rate Limits

The gem automatically handles rate limiting with exponential backoff:

- **Production**: 100 req/sec global, 20 req/sec per endpoint, 50 concurrent
- **Sandbox**: 20 req/sec global, 5 req/sec per endpoint, 10 concurrent

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
- [Gem Documentation](https://rubydoc.info/gems/airwallex)
- [Integration Guides](./docs/internal/)

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
