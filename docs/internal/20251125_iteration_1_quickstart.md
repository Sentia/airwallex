# Iteration 1 - Quick Start

**Sprint 1, Iteration 1**  
**Date:** 25 November 2025  
**Status:** ✅ Complete

## What Was Built

Core infrastructure for the Airwallex Ruby gem including:

1. ✅ Complete directory structure
2. ✅ Configuration management (sandbox/production)
3. ✅ HTTP client with Faraday
4. ✅ Bearer token authentication with auto-refresh
5. ✅ Comprehensive error handling
6. ✅ Automatic idempotency
7. ✅ Webhook signature verification
8. ✅ Utility helpers
9. ✅ Zero Rubocop offenses

## Quick Test

```ruby
require 'airwallex'

# Configure the gem
Airwallex.configure do |config|
  config.api_key = 'your_api_key'
  config.client_id = 'your_client_id'
  config.environment = :sandbox
end

# Check configuration
puts Airwallex.configuration.api_url
# => https://api-demo.airwallex.com/api/v1

# Client is ready (authentication happens automatically on first request)
client = Airwallex.client
```

## Files Created

```text
lib/airwallex.rb                       - Main module with configuration
lib/airwallex/version.rb               - Version constant
lib/airwallex/configuration.rb         - Configuration class
lib/airwallex/client.rb                - HTTP client with Faraday
lib/airwallex/errors.rb                - Exception hierarchy
lib/airwallex/util.rb                  - Helper utilities
lib/airwallex/webhook.rb               - Webhook verification
lib/airwallex/middleware/idempotency.rb     - Auto request_id
lib/airwallex/middleware/auth_refresh.rb    - Token management
```

## Key Features

### Environment Safety
- Defaults to `:sandbox` to prevent accidental production transactions
- Validates environment selection
- Dynamic URL generation

### Authentication
- Automatic Bearer token exchange
- 30-minute token lifetime with 5-minute refresh buffer
- Thread-safe token management
- Transparent 401 retry

### Idempotency
- Automatic UUID v4 generation for `request_id`
- Injected into request body (Airwallex specification)
- Safe request retries

### Error Handling
- HTTP status mapped to specific exceptions
- Polymorphic error body parsing
- Detailed error information (`code`, `message`, `param`, `details`)

### Webhook Security
- HMAC-SHA256 signature verification
- Replay attack protection (5-minute tolerance)
- Constant-time comparison

## What's Next

**Iteration 2:** Testing Infrastructure
- Set up RSpec, WebMock, VCR
- Write comprehensive tests
- Achieve 90%+ coverage

**Sprint 2:** Resource Implementation
- APIResource base class
- Payment Intent resource
- Transfer resource
- Pagination system

## Validation

```bash
# Check for errors
bundle exec rubocop lib/
# => 9 files inspected, no offenses detected ✅

# Test gem loading
bundle exec ruby -e "require './lib/airwallex'; puts 'OK'"
# => OK ✅

# Test configuration
bundle exec ruby -e "
  require './lib/airwallex'
  Airwallex.configure { |c| c.api_key = 'test'; c.client_id = 'test' }
  puts Airwallex.configuration.api_url
"
# => https://api-demo.airwallex.com/api/v1 ✅
```

## Time Spent

Approximately 4 hours for:
- Directory structure setup
- Core class implementation
- Faraday middleware
- Rubocop configuration
- Documentation

## Notes

- All code follows Ruby 3.1+ standards
- No external API calls made yet (no tests)
- Architecture matches research blueprints exactly
- Ready for test implementation
