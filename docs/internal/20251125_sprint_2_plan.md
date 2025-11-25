# Sprint 2 Implementation Plan
**Date:** 25 November 2025  
**Sprint:** 2 - API Resources & Operations  
**Status:** 🔄 IN PROGRESS

---

## Sprint Goals

Build the resource abstraction layer that enables intuitive, Ruby-idiomatic API interactions. Implement the first set of core resources (PaymentIntent, Transfer, Beneficiary) with full CRUD operations and pagination support.

### Primary Objectives
1. Create APIResource base class with shared behavior
2. Implement API operation mixins (Create, Retrieve, Update, List, Delete)
3. Build unified pagination system (cursor + offset)
4. Implement 3 core resources with full functionality
5. Add request/response object wrapping
6. Implement nested resource support

---

## Work Items

### 1. APIResource Base Class
**Priority: Critical**  
**Estimated: 6 hours**

#### 1.1 Base Resource Structure
Create `lib/airwallex/api_resource.rb`:

```ruby
module Airwallex
  class APIResource
    attr_reader :id
    attr_accessor :attributes
    
    def initialize(attributes = {})
      @attributes = Util.deep_symbolize_keys(attributes)
      @id = @attributes[:id]
    end
    
    # Class methods
    def self.resource_name
      # Convert PaymentIntent -> payment_intent
    end
    
    def self.resource_path
      # /api/v1/pa/payment_intents
    end
    
    # Instance methods
    def refresh
      # Re-fetch from API
    end
    
    def to_hash
      @attributes
    end
  end
end
```

**Features:**
- Dynamic attribute accessors (`payment_intent.amount`)
- Resource name inference from class name
- Automatic path generation
- Hash/JSON serialization
- Attribute dirty tracking (for updates)

**Acceptance Criteria:**
- [ ] Base class instantiatable with hash
- [ ] Attributes accessible via dot notation
- [ ] Resource name correctly inferred
- [ ] Resource path generated correctly
- [ ] to_hash returns all attributes
- [ ] refresh fetches latest data

---

### 2. API Operations Mixins
**Priority: Critical**  
**Estimated: 8 hours**

#### 2.1 Create Operation
`lib/airwallex/api_operations/create.rb`:

```ruby
module Airwallex
  module APIOperations
    module Create
      def create(params = {}, opts = {})
        response = Airwallex.client.post(
          "#{resource_path}/create",
          params,
          opts[:headers] || {}
        )
        new(response)
      end
    end
  end
end
```

#### 2.2 Retrieve Operation
`lib/airwallex/api_operations/retrieve.rb`:

```ruby
module Airwallex
  module APIOperations
    module Retrieve
      def retrieve(id, opts = {})
        response = Airwallex.client.get(
          "#{resource_path}/#{id}",
          {},
          opts[:headers] || {}
        )
        new(response)
      end
    end
  end
end
```

#### 2.3 Update Operation
`lib/airwallex/api_operations/update.rb`:

```ruby
module Airwallex
  module APIOperations
    module Update
      module ClassMethods
        def update(id, params = {}, opts = {})
          # PUT request
        end
      end
      
      module InstanceMethods
        def update(params = {})
          # Update current instance
        end
        
        def save
          # Save dirty attributes
        end
      end
    end
  end
end
```

#### 2.4 Delete Operation
`lib/airwallex/api_operations/delete.rb`:

```ruby
module Airwallex
  module APIOperations
    module Delete
      def delete(id, opts = {})
        Airwallex.client.delete("#{resource_path}/#{id}")
        true
      end
    end
  end
end
```

#### 2.5 List Operation
`lib/airwallex/api_operations/list.rb`:

```ruby
module Airwallex
  module APIOperations
    module List
      def list(params = {}, opts = {})
        response = Airwallex.client.get(
          resource_path,
          params,
          opts[:headers] || {}
        )
        
        ListObject.new(
          data: response[:items],
          has_more: response[:has_more],
          resource_class: self
        )
      end
    end
  end
end
```

**Acceptance Criteria:**
- [ ] Create mixin works for all resources
- [ ] Retrieve fetches single resource by ID
- [ ] Update supports both class and instance methods
- [ ] Delete returns boolean success
- [ ] List returns paginated collection
- [ ] All operations support request options

---

### 3. Pagination System
**Priority: High**  
**Estimated: 6 hours**

#### 3.1 ListObject
`lib/airwallex/list_object.rb`:

```ruby
module Airwallex
  class ListObject
    include Enumerable
    
    attr_reader :data, :has_more, :next_cursor
    
    def initialize(data:, has_more:, resource_class:, next_cursor: nil)
      @data = data.map { |item| resource_class.new(item) }
      @has_more = has_more
      @next_cursor = next_cursor
      @resource_class = resource_class
    end
    
    def each(&block)
      @data.each(&block)
    end
    
    def next_page(params = {})
      # Fetch next page using cursor or offset
    end
    
    def auto_paging_each(&block)
      # Automatically fetch all pages
    end
  end
end
```

**Features:**
- Enumerable interface (`each`, `map`, `select`)
- Cursor-based pagination (Airwallex default)
- Offset-based pagination (fallback)
- Auto-paging iterator
- Lazy loading support

**Acceptance Criteria:**
- [ ] ListObject wraps array of resources
- [ ] Enumerable methods work
- [ ] next_page fetches subsequent page
- [ ] auto_paging_each iterates all pages
- [ ] Handles both cursor and offset pagination

---

### 4. Resource Implementations
**Priority: High**  
**Estimated: 12 hours**

#### 4.1 PaymentIntent Resource
`lib/airwallex/resources/payment_intent.rb`:

```ruby
module Airwallex
  class PaymentIntent < APIResource
    extend APIOperations::Create
    extend APIOperations::Retrieve
    extend APIOperations::List
    include APIOperations::Update
    
    def self.resource_path
      "/api/v1/pa/payment_intents"
    end
    
    # Custom methods
    def confirm(params = {})
      response = Airwallex.client.post(
        "#{self.class.resource_path}/#{id}/confirm",
        params
      )
      refresh_from(response)
    end
    
    def cancel(params = {})
      response = Airwallex.client.post(
        "#{self.class.resource_path}/#{id}/cancel",
        params
      )
      refresh_from(response)
    end
    
    def capture(params = {})
      # Capture authorized amount
    end
  end
end
```

**Fields:**
- `id`, `amount`, `currency`, `status`
- `merchant_order_id`, `return_url`
- `payment_method`, `captured_amount`
- `created_at`, `updated_at`

**Methods:**
- `PaymentIntent.create(params)` - Create new intent
- `PaymentIntent.retrieve(id)` - Get by ID
- `PaymentIntent.list(params)` - List with filters
- `#confirm(payment_method)` - Confirm payment
- `#cancel(reason)` - Cancel intent
- `#capture(amount)` - Capture authorized

#### 4.2 Transfer Resource
`lib/airwallex/resources/transfer.rb`:

```ruby
module Airwallex
  class Transfer < APIResource
    extend APIOperations::Create
    extend APIOperations::Retrieve
    extend APIOperations::List
    
    def self.resource_path
      "/api/v1/transfers"
    end
    
    def cancel
      # Cancel pending transfer
    end
  end
end
```

**Fields:**
- `id`, `beneficiary_id`, `amount`, `source_currency`
- `destination_currency`, `transfer_method`, `status`
- `fee`, `reason`, `created_at`

**Methods:**
- `Transfer.create(params)` - Create transfer
- `Transfer.retrieve(id)` - Get by ID
- `Transfer.list(params)` - List transfers
- `#cancel` - Cancel pending

#### 4.3 Beneficiary Resource
`lib/airwallex/resources/beneficiary.rb`:

```ruby
module Airwallex
  class Beneficiary < APIResource
    extend APIOperations::Create
    extend APIOperations::Retrieve
    extend APIOperations::List
    extend APIOperations::Delete
    
    def self.resource_path
      "/api/v1/beneficiaries"
    end
  end
end
```

**Fields:**
- `id`, `bank_details`, `beneficiary_type`
- `company_name`, `first_name`, `last_name`
- `address`, `entity_type`, `created_at`

**Methods:**
- `Beneficiary.create(params)` - Create beneficiary
- `Beneficiary.retrieve(id)` - Get by ID
- `Beneficiary.list(params)` - List all
- `Beneficiary.delete(id)` - Delete beneficiary

**Acceptance Criteria:**
- [ ] All 3 resources implement expected methods
- [ ] CRUD operations work end-to-end
- [ ] Custom methods (confirm, cancel, capture) work
- [ ] Pagination works for list operations
- [ ] All fields accessible via dot notation

---

### 5. Response Object Wrapping
**Priority: Medium**  
**Estimated: 4 hours**

#### 5.1 Response Object
`lib/airwallex/response.rb`:

```ruby
module Airwallex
  class Response
    attr_reader :data, :http_status, :http_headers, :request_id
    
    def initialize(data:, http_status:, http_headers:)
      @data = data
      @http_status = http_status
      @http_headers = http_headers
      @request_id = http_headers['x-request-id']
    end
    
    def success?
      (200..299).include?(http_status)
    end
  end
end
```

**Features:**
- Wraps API response with metadata
- Exposes HTTP status and headers
- Provides request_id for support
- Success/failure predicates

**Acceptance Criteria:**
- [ ] Response object wraps all API calls
- [ ] HTTP metadata accessible
- [ ] request_id extracted from headers
- [ ] Backward compatible with direct data access

---

### 6. Testing
**Priority: High**  
**Estimated: 10 hours**

#### 6.1 Resource Tests
Create test files:
- `spec/airwallex/api_resource_spec.rb`
- `spec/airwallex/list_object_spec.rb`
- `spec/airwallex/resources/payment_intent_spec.rb`
- `spec/airwallex/resources/transfer_spec.rb`
- `spec/airwallex/resources/beneficiary_spec.rb`

**Test Coverage:**
- Resource initialization and attribute access
- CRUD operations for each resource
- Pagination (next_page, auto_paging_each)
- Custom resource methods (confirm, cancel, capture)
- Error handling for each operation
- Response object wrapping

**Acceptance Criteria:**
- [ ] All resources tested with WebMock stubs
- [ ] Pagination tested with multiple pages
- [ ] Error cases covered
- [ ] Test coverage > 90%

---

## Definition of Done

- [ ] All 3 resources fully implemented
- [ ] CRUD operations work end-to-end
- [ ] Pagination system complete
- [ ] All tests passing (0 failures)
- [ ] 0 Rubocop offenses
- [ ] Code coverage > 90%
- [ ] README updated with resource examples
- [ ] Manual testing in sandbox complete

---

## Dependencies

**New Gems:**
- None (using existing Faraday stack)

**Internal:**
- Sprint 1 infrastructure (Client, Configuration, Errors)

---

## Risk Mitigation

| Risk | Impact | Mitigation |
|------|--------|-----------|
| API response schema changes | High | Pin API version, use VCR cassettes |
| Nested resource complexity | Medium | Start simple, iterate on feedback |
| Pagination edge cases | Medium | Comprehensive test coverage |
| Resource name conflicts | Low | Use explicit resource_path override |

---

## Success Metrics

- PaymentIntent.create works in sandbox ✅
- Transfer.create works in sandbox ✅
- Beneficiary CRUD works in sandbox ✅
- Pagination fetches multiple pages ✅
- All tests green ✅
- Zero Rubocop offenses ✅

---

## Out of Scope (Sprint 3+)

- Nested resources (PaymentConsent, PaymentMethod)
- Webhook handling (already done in Sprint 1)
- File upload resources
- Batch operations
- Rate limit header parsing
- Connected accounts (x-on-behalf-of)

---

## Sprint 2 Timeline

**Week 1:**
- Day 1-2: APIResource base class + mixins
- Day 3-4: Pagination system
- Day 5: PaymentIntent resource

**Week 2:**
- Day 1: Transfer resource
- Day 2: Beneficiary resource
- Day 3-4: Testing all resources
- Day 5: Documentation + sandbox validation

---

## Next Steps

After Sprint 2 completion, we'll have a fully functional gem ready for:
- Publishing to RubyGems (v0.1.0)
- Production use for basic payment workflows
- Community feedback and iteration

**Sprint 3 Preview:**
- Additional resources (Account, Card, Payout)
- Advanced features (refunds, disputes)
- Performance optimizations
- Enhanced documentation
