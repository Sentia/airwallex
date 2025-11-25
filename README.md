# Airwallex Ruby Gem

A Ruby client library for the [Airwallex API](https://www.airwallex.com/docs/api), providing access to payment acceptance and payout capabilities.

## Overview

This gem provides a Ruby interface to Airwallex's payment infrastructure, designed for Ruby 3.1+ applications. It includes core functionality for authentication management, idempotency guarantees, webhook verification, and multi-environment support.

**Current Features (v0.1.0):**

- **Authentication**: Bearer token authentication with automatic refresh
- **Payment Acceptance**: Payment intent creation, confirmation, and management
- **Payouts**: Transfer creation and beneficiary management
- **Idempotency**: Automatic request deduplication for safe retries
- **Pagination**: Unified interface over cursor-based and offset-based pagination
- **Webhook Security**: HMAC-SHA256 signature verification with replay protection
- **Sandbox Support**: Full testing environment for development

**Note:** This is an initial MVP release. Additional resources (FX, cards, refunds, etc.) will be added in future versions.

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
├── api_operations/        # CRUD operation mixins (Create, Retrieve, List, Update, Delete)
├── resources/             # Implemented resources
│   ├── payment_intent.rb  # Payment acceptance
│   ├── transfer.rb        # Payouts
│   └── beneficiary.rb     # Payout beneficiaries
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

## API Coverage (v0.1.0)

### Currently Implemented Resources

- **Payment Acceptance**: PaymentIntent (create, retrieve, list, update, confirm, cancel, capture)
- **Payouts**: Transfer (create, retrieve, list, cancel), Beneficiary (create, retrieve, list, delete)
- **Webhooks**: Event handling, HMAC-SHA256 signature verification

### Coming in Future Versions

- Refunds and disputes
- Foreign exchange (rates, quotes, conversions)
- Payment methods management
- Global accounts
- Card issuing
- Additional payout methods

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
