# Sprint 4 Plan - Batch Operations & Disputes

**Date:** 2025-11-25  
**Sprint Goal:** Add batch transfer operations and dispute management capabilities

## Overview

Sprint 4 expands the gem's capabilities for high-volume operations and payment dispute handling. These features are critical for:
- **Batch Operations**: Process multiple payouts efficiently (e.g., marketplace payouts, payroll)
- **Disputes**: Handle chargebacks and payment disputes programmatically

## Resources to Implement

### 1. BatchTransfer Resource

Batch transfers allow creating multiple transfers in a single operation, reducing API calls and improving efficiency for bulk payouts.

**API Endpoint:** `/api/v1/batch_transfers`

**Operations:**
- `create` - Create a batch of transfers
- `retrieve` - Get batch transfer details
- `list` - List all batch transfers

**Key Fields:**
- `id` - Batch transfer ID
- `status` - `PROCESSING`, `COMPLETED`, `PARTIALLY_FAILED`, `FAILED`
- `transfers` - Array of individual transfers with their statuses
- `total_count` - Total number of transfers in batch
- `success_count` - Number of successfully processed transfers
- `failed_count` - Number of failed transfers
- `source_currency` - Currency for all transfers
- `request_id` - For idempotency

**Usage Example:**
```ruby
batch = Airwallex::BatchTransfer.create(
  request_id: "batch_#{Time.now.to_i}",
  source_currency: "USD",
  transfers: [
    {
      beneficiary_id: "ben_001",
      amount: 100.00,
      reason: "Payout 1"
    },
    {
      beneficiary_id: "ben_002",
      amount: 200.00,
      reason: "Payout 2"
    }
  ]
)

# Check individual transfer statuses
batch.transfers.each do |transfer|
  puts "Transfer #{transfer.id}: #{transfer.status}"
end
```

**Testing Requirements:**
- Create batch transfer with multiple items
- Retrieve batch transfer
- List batch transfers with pagination
- Handle partial failures (some transfers succeed, others fail)
- Test idempotency with request_id

---

### 2. Dispute Resource

Disputes represent chargebacks or payment disputes initiated by cardholders. This resource allows merchants to respond to disputes programmatically.

**API Endpoint:** `/api/v1/disputes`

**Operations:**
- `retrieve` - Get dispute details
- `list` - List all disputes with filtering
- `accept` - Accept a dispute (no challenge)
- `submit_evidence` - Submit evidence to challenge a dispute

**Key Fields:**
- `id` - Dispute ID
- `payment_intent_id` - Related payment
- `amount` - Disputed amount
- `currency` - Dispute currency
- `reason` - Dispute reason (e.g., `fraudulent`, `unrecognized`, `product_not_received`)
- `status` - `OPEN`, `UNDER_REVIEW`, `WON`, `LOST`, `ACCEPTED`
- `evidence_due_by` - Deadline to submit evidence (timestamp)
- `created_at` - When dispute was created

**Custom Methods:**
- `accept` - Accept dispute without challenging
- `submit_evidence(evidence_params)` - Submit evidence to challenge

**Usage Example:**
```ruby
# List disputes
disputes = Airwallex::Dispute.list(status: 'OPEN')

# Get specific dispute
dispute = Airwallex::Dispute.retrieve('dis_abc123')

# Submit evidence to challenge
dispute.submit_evidence(
  customer_communication: "Proof of email exchange",
  shipping_documentation: "Tracking number XYZ",
  customer_signature: "Signed receipt"
)

# Or accept dispute
dispute.accept
```

**Testing Requirements:**
- Retrieve dispute by ID
- List disputes with status filter
- List disputes by payment_intent_id
- Accept dispute
- Submit evidence
- Handle evidence submission errors

---

### 3. Dispute Evidence Helper

A convenience class for building evidence submissions with proper field validation.

**Purpose:** Make it easier to construct evidence objects with the correct fields.

**Usage Example:**
```ruby
evidence = Airwallex::DisputeEvidence.new(
  customer_communication: "Email thread showing delivery confirmation",
  shipping_tracking_number: "1Z999AA10123456784",
  receipt: "file_id_123"
)

dispute.submit_evidence(evidence.to_h)
```

---

## Implementation Order

1. **BatchTransfer Resource** (Priority: High)
   - File: `lib/airwallex/resources/batch_transfer.rb`
   - Operations: Create, Retrieve, List
   - Test: `spec/airwallex/resources/batch_transfer_spec.rb`

2. **Dispute Resource** (Priority: High)
   - File: `lib/airwallex/resources/dispute.rb`
   - Operations: Retrieve, List, custom methods (accept, submit_evidence)
   - Test: `spec/airwallex/resources/dispute_spec.rb`

3. **DisputeEvidence Helper** (Priority: Medium)
   - File: `lib/airwallex/dispute_evidence.rb`
   - Simple data structure for evidence building
   - Test: Include in dispute_spec.rb

---

## Success Criteria

- ✅ All 3 resources implemented with proper operation mixins
- ✅ Custom methods (accept, submit_evidence) working
- ✅ Comprehensive test coverage (aim for 20+ new tests)
- ✅ Manual testing successful with sandbox API
- ✅ README updated with usage examples
- ✅ CHANGELOG updated
- ✅ Zero Rubocop offenses
- ✅ All existing tests still passing

---

## Testing Strategy

### Unit Tests
- Each resource CRUD operation
- Custom methods with proper parameter handling
- Error handling for all endpoints
- Pagination for list operations

### Manual Testing
- Create test script: `local_tests/test_sprint4_resources.rb`
- Test batch transfer with 3+ items
- Test dispute retrieval and status filtering
- Test evidence submission flow

---

## Documentation Updates

### README.md
Add sections:
- "Batch Transfers" - Example of creating batch payouts
- "Managing Disputes" - Example of listing and responding to disputes

### CHANGELOG.md
Add to Unreleased:
```markdown
### Added
- BatchTransfer resource (create, retrieve, list)
- Dispute resource (retrieve, list, accept, submit_evidence)
- DisputeEvidence helper for building evidence submissions
- XX new tests (XXX total)
```

---

## Estimated Effort

- Implementation: 2-3 hours
- Testing: 1-2 hours
- Documentation: 30 minutes
- Total: ~4-5 hours

---

## Future Considerations (Sprint 5+)

Based on research document priorities:
1. **Foreign Exchange (FX)** - Rate quotes and conversions
2. **Card Issuing** - Virtual/physical card management
3. **Enhanced Webhooks** - Event type registry and handlers
4. **Account Balance** - Real-time balance checking
5. **Schema Validation** - Dynamic form validation for beneficiaries

---

## Notes

- Batch transfers reduce API calls significantly for bulk operations
- Dispute handling is critical for merchants accepting card payments
- Evidence submission has strict deadlines (evidence_due_by)
- Both resources benefit from proper webhook integration (future enhancement)
