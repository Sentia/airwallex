

# **Architectural Blueprint and Technical Implementation Strategy for the Airwallex Ruby Gem**

## **1\. Executive Summary and Strategic Alignment**

The development of a robust, production-grade Ruby gem for the Airwallex API represents a significant infrastructure undertaking that requires a nuanced understanding of distributed financial systems. This report provides a comprehensive architectural analysis of the Airwallex API ecosystem, derived from an exhaustive review of official documentation, technical specifications, and integration patterns. The primary objective is to lay the foundational blueprints for a Ruby 3.1+ library utilizing rubocop for static analysis and faraday for HTTP transport layer abstraction.

The Airwallex API is a sprawling financial infrastructure interface that encompasses global business accounts, payments acceptance, foreign exchange (FX), and card issuing.1 Unlike typical REST APIs where a failed request is a mere inconvenience or a UI glitch, errors in this domain can result in duplicate financial transactions, locked funds, regulatory non-compliance, or significant monetary loss. Therefore, a client library interacting with this system must prioritize **correctness, idempotency, and type safety** above all else.

This research highlights critical architectural patterns necessary for the gem. First, the API utilizes a strict separation of concerns between its sandbox and production environments, extending beyond simple URL changes to include distinct credential sets and rate-limiting behaviors.2 Second, the authentication mechanism is multi-layered, involving not just static API keys but also short-lived Bearer tokens that require active lifecycle management, and in some cases, even shorter-lived Strong Customer Authentication (SCA) tokens.4 Third, the API is in a transitional state regarding pagination, necessitating a gem architecture that can seamlessly handle both legacy offset-based and modern cursor-based traversal strategies.1 Finally, the enforcement of idempotency via request\_id in the payload body—rather than the header—presents a specific implementation detail that deviates from common industry standards like Stripe, requiring careful middleware design.1

The following sections detail the API structure, endpoint behaviors, and implementation strategies required to build a gem that meets the rigorous demands of enterprise financial software.

## **2\. API Environment and Connection Architecture**

The fundamental connectivity layer of the Airwallex Ruby gem must be designed to handle the strict environmental segmentation enforced by the platform. The Airwallex API operates on a model where the testing (Sandbox) and live (Production) environments are completely isolated universes. This separation extends beyond simple base URL changes; it involves distinct credential sets, rate limits, and behavioral guarantees, which the gem must abstract for the end-user to prevent catastrophic configuration errors.2

### **2.1. Endpoint Topology and Configuration**

The gem must support configuration for at least two primary environments. Hardcoding these URLs is discouraged; instead, a configuration block pattern should be employed to allow runtime injection of these values, facilitating testing against mocks or proxy servers. The primary entry points for the API differ significantly between environments.

| Environment | Base URL | Purpose |
| :---- | :---- | :---- |
| **Sandbox** | https://api-demo.airwallex.com/api/v1/ | Development, integration testing, and simulation of financial flows without real money movement. This environment mimics production behavior but does not connect to real banking networks.1 |
| **Production** | https://api.airwallex.com/api/v1/ | Live financial transactions. Strict security, higher rate limits, and real money movement apply.1 |
| **Files (Sandbox)** | https://files-demo.airwallex.com | Dedicated host for uploading documents for KYC/KYB checks in the test environment. Separation of file hosting reduces load on the transactional API.7 |
| **Files (Production)** | https://files.airwallex.com | Dedicated host for live compliance documents and evidence submission.7 |

**Architectural Implication:** The Airwallex.configure block in the Ruby gem must accept an environment symbol (e.g., :sandbox or :production). The internal client must dynamically interpolate the correct API and Files hostnames based on this selection. Defaulting to :production is unsafe; the safer default is :sandbox to prevent accidental real-money transactions during initial setup. Furthermore, the gem should validate that the credentials provided match the selected environment format, as Client IDs often differ in prefix or format between environments.7

### **2.2. Protocol and Transport Security**

Communication is strictly HTTPS, ensuring transport layer security for all data in transit. The API follows REST principles, utilizing standard HTTP verbs (GET, POST, PUT, DELETE) to represent resource operations.1 The transport layer, which will be managed by the faraday gem, must be configured to enforce TLS 1.2 or higher. Financial APIs frequently deprecate older protocols (TLS 1.0/1.1) to maintain PCI-DSS compliance, and the Ruby gem should proactively enforce this to avoid negotiation failures on older systems.

Headers and Content Negotiation:  
The gem must inject a specific set of headers into every request to ensure successful processing. Failure to provide these results in 400 Bad Request or 401 Unauthorized errors.

* **Content-Type:** Must be strictly application/json for all operational endpoints. The API expects JSON payloads and will fail to parse requests sent as application/x-www-form-urlencoded or other formats, except for specific OAuth token exchanges.1  
* **User-Agent:** While not explicitly mandated by the snippets, it is best practice for the gem to identify itself (e.g., Airwallex-Ruby/1.0.0 Ruby/3.1.0). This aids in debugging with Airwallex support and allows the platform to track SDK usage versions.  
* **x-api-version:** The API supports date-based versioning (e.g., 2019-09-09). This allows the API to evolve without breaking existing integrations.9 The gem should pin to a specific, tested version of the API to ensure stability. Overriding this via headers is possible but should be reserved for migration testing.10 The report notes that major changes to resources like "Global Accounts" and "Billing" are tied to specific API versions, making explicit version pinning in the gem critical for predictable behavior.1

### **2.3. Rate Limiting and Throttling Strategies**

Airwallex implements a robust rate-limiting strategy that the gem must handle gracefully to ensure system resilience. These limits are designed to protect the platform from abuse and ensure fair resource allocation.3

Limits Analysis:  
The limits are bifurcated by environment and scope:

* **Production:**  
  * **Global Limit:** 100 requests per second. This is the total throughput allowed for the account.3  
  * **Endpoint Limit:** 20 requests per second. This prevents hammering a specific resource (e.g., repeatedly querying the same balance endpoint).3  
  * **Concurrency:** Capped at 50 simultaneous requests. This limits the number of open connections awaiting a response.3  
* **Sandbox:**  
  * **Global Limit:** 20 requests per second.3  
  * **Endpoint Limit:** 10 requests per second.3  
  * **Concurrency:** Capped at 10 simultaneous requests.3

Handling Strategy:  
When a limit is exceeded, the API returns 429 Too Many Requests. While some APIs provide explicit headers like X-RateLimit-Remaining to allow clients to throttle preemptively, the Airwallex snippets emphasize the status code as the primary signal.3  
Gem Implementation:  
The Faraday stack should include a Retry middleware configured with sophisticated logic. Generic retries are dangerous in financial APIs due to the risk of non-idempotent execution (double-charging).

* **Safe Retries:** GET requests (read operations) can be safely retried on 429 errors with exponential backoff.  
* **Unsafe Retries:** POST (creation/mutation) requests must **only** be retried if the request included a mechanism for idempotency. As discussed in later sections, Airwallex uses request\_id in the body for this. If the gem sends a request without a reliable ID and receives a 429 or a timeout (504), it *cannot* safely retry without risking duplication.  
* **Backoff:** The gem should implement Jittered Exponential Backoff. This introduces randomness into the wait time between retries, preventing "thundering herd" problems where all client threads retry simultaneously when the rate limit resets.

## **3\. Authentication and Authorization Architectures**

Authentication is the gatekeeper of the Airwallex API. The research indicates that a single authentication method is insufficient; the gem must support multiple strategies to cater to different use cases, including Direct Merchant integration and Platform/Connect models. The complexity lies in the lifecycle management of the access tokens, which are short-lived and must be refreshed regularly.4

### **3.1. Bearer Token Authentication (The Standard Flow)**

The primary mechanism for authenticating API requests is the **Bearer Token**. Unlike simpler APIs that might use the API key directly in every request header, Airwallex requires an exchange of long-lived credentials for a short-lived access token. This adds a layer of security, as the long-lived keys are exposed less frequently.9

**The Handshake Mechanism:**

1. **Credentials:** The user possesses a Client ID and an API Key (either Admin or Scoped) obtained from the Airwallex dashboard.4 Admin keys have broad access, while scoped keys are restricted to specific permissions, adhering to the principle of least privilege.4  
2. **Exchange:** The gem must POST these credentials to /api/v1/authentication/login.1  
   * Headers: x-client-id, x-api-key.  
   * Body: Empty or specific login-as params if acting on behalf of another.  
3. **Response:** A JSON object containing the token and expiration details.1  
   * Example: {"token": "eyJhb...", "expires\_at": "..."}.  
4. **Usage:** Subsequent requests must include Authorization: Bearer \<token\> in the header.1

Token Lifecycle Management:  
The access token is valid for 30 minutes.7 This relatively short lifespan necessitates an auto-refresh mechanism within the gem.

* **Lazy Refresh:** The client checks if the token is expired (or about to expire, e.g., within 5 minutes) before making a request. If expired, it calls the login endpoint again.  
* **Middleware Approach:** For a Ruby gem, a **Lazy Refresh** approach within the Faraday middleware is preferred. The middleware can intercept 401 Unauthorized responses, check if the token might have expired, refresh the token, and replay the request transparently. This shields the developer from manually handling token expiration errors.

### **3.2. Platform and Connected Account Authentication (OAuth)**

For platforms managing other businesses (Connected Accounts), the authentication flow differs significantly. The gem must support the OAuth pattern to act on behalf of other users. This allows a platform (e.g., a marketplace) to manage payments for its sellers.11

**Mechanism:**

1. **Authorization Code:** Obtained via user redirection to an Airwallex authorization page.  
2. **Token Exchange:** The code is exchanged for a refresh\_token (valid 90 days) and an access\_token.11  
3. **Acting on Behalf:**  
   * **Header:** x-on-behalf-of: \<account\_id\> is used when a platform performs actions on a connected account's resources.13  
   * **Scoped Keys:** Alternatively, scoped API keys can be generated for specific accounts.4

Gem Architecture:  
The gem should introduce a Session or Client class that can be initialized either with (client\_id, api\_key) for direct mode or (access\_token, refresh\_token) for OAuth mode. This polymorphism allows the same resource methods (e.g., Payment.create) to work regardless of the underlying auth strategy. The OAuth flow specifically requires a mechanism to persist and update the refresh\_token since it rotates; the gem should expose hooks to allow the host application to save the new refresh token to its database whenever it changes.11

### **3.3. Strong Customer Authentication (SCA)**

A critical edge case identified in the research is SCA enforcement for sensitive data retrieval (e.g., older transactions, full balances).5 This is a regulatory requirement in many jurisdictions.

* **Trigger:** Accessing sensitive endpoints may trigger an SCA requirement if the session is not already stepped-up.  
* **Token:** A specific SCA token (valid for only **5 minutes**) is issued after the user completes 2FA.5  
* **Implication:** The gem must be capable of handling "Step-up" authentication exceptions. If an API call fails due to missing SCA (likely a 403 or specific error code), the gem should raise a specific Airwallex::SCARequired error. This error object should ideally contain the details needed for the developer to initiate the user-facing 2FA flow. Once the SCA token is obtained, the developer would pass it back to the gem (perhaps via a headers option) to retry the request.5

## **4\. Idempotency and Distributed Consistency**

In financial software, idempotency is the mechanism that ensures a $100 transfer executed twice due to a network timeout results in a single $100 charge, not $200. It is the bedrock of data integrity in distributed systems.

### **4.1. The request\_id Paradigm**

The research reveals a crucial nuance in how Airwallex handles idempotency compared to other providers like Stripe. While Stripe uses a specific header (Idempotency-Key), Airwallex documentation explicitly and repeatedly instructs developers to include request\_id inside the **request body** for transactional endpoints like Conversions, Payouts, and Payments.1

**Behavioral Specification:**

* **Mechanism:** When a request is received with a request\_id that has been seen before:  
  * If the request parameters match the original request, the API returns the *original* successful response. This is a "replay" and is safe.  
  * If the request parameters differ, or if the original request failed in a non-recoverable way, the API may return a request\_id\_duplicate error.15  
* **Concurrency:** If request\_id is a duplicate of a request that is currently *processing*, the API behavior is implicitly a race condition handling scenario, typically resulting in the second request waiting or being rejected.

### **4.2. Implementation in Ruby**

The gem should abstract this to prevent developer error. It is easy to forget to add a unique ID, so the gem should enforce "safe by default" behavior.

1. **Auto-Generation:** If the user does not supply a request\_id in the arguments for a create or update method, the gem should automatically generate a UUID (v4).  
2. **Explicit Override:** Allow the user to pass a specific request\_id for their own reconciliation logic (e.g., matching their internal database ID).

Ruby

\# Conceptual implementation of Idempotency Middleware  
def create(params \= {})  
  \# Check if request\_id exists in params, if not, generate it  
  params\[:request\_id\] ||\= SecureRandom.uuid  
  post('/transfers', params)  
end

This approach protects users who may not fully understand the risks of network retries. If a timeout occurs, and the user (or the gem's retry middleware) retries the request, the presence of the preserved request\_id ensures that Airwallex treats it as the same transaction.

## **5\. Pagination Standards and Transition**

The Airwallex API is currently undergoing a transition in pagination standards. The gem must support both legacy and modern patterns to ensure full coverage of all endpoints without confusing the developer.1

### **5.1. Offset-Based (Legacy)**

Older endpoints (and some current ones like Payouts) utilize an offset-based approach.13

* **Parameters:** page\_num (integer, 0-indexed) and page\_size (integer).  
* **Mechanism:** To get the next page, the client increments page\_num.  
* **Drawbacks:** Performance degrades on deep pages (the "offset problem" in databases); prone to data drift if items are inserted or deleted while paging (shifting the offset).

### **5.2. Cursor-Based (Modern)**

Newer endpoints, particularly "Global Accounts" and "Billing," have shifted to cursor-based pagination.1

* **Parameters:** page\_before or page\_after (cursor strings), and page\_size.  
* **Mechanism:** The response contains a has\_more boolean and/or next\_page\_cursor.  
* **Advantages:** O(1) fetch time regardless of depth; consistent ordering even with high-velocity writes.

### **5.3. The AutoPaginator Pattern**

To provide a superior developer experience (DX), the gem should implement an Enumerable wrapper. This allows Ruby developers to iterate through resources without managing loops, cursors, or page numbers manually.

* Design:  
  The list methods should return a Airwallex::List object. This object includes the raw items and metadata. It should also implement an auto\_paging\_each method that yields items one by one, transparently fetching the next page when the current buffer is exhausted.  
* **Abstraction:** The AutoPaginator class must inspect the response to determine if it needs to use page\_num or page\_after for the next request, shielding the user from the underlying API inconsistency. It effectively polyfills a unified interface over the divergent API behaviors.

## **6\. Resource-Specific Architectures**

Different domains within the Airwallex API have unique requirements that the gem must model accurately.

### **6.1. Payments and 3DS**

The Payments API is complex, involving PaymentIntents (the state of the transaction) and PaymentAttempts (the specific execution). A key complexity here is **3D Secure (3DS)** authentication.19

* **Flow:** When confirming a payment intent via the API (server-side), the response might indicate that 3DS is required.  
* **Gem Role:** The gem must return a structured object that clearly indicates the next\_action required. If the status is requires\_customer\_action, the gem should expose the redirect\_url or 3DS data needed for the frontend to complete the challenge.

### **6.2. Payouts and Schema Validation**

Global payouts require varying beneficiary data based on the destination country and currency (e.g., Routing Number in the US vs. IBAN in Europe vs. CNAPS in China). Airwallex handles this via a **Schema API**.20

* **Problem:** Hardcoding validation rules in the gem is futile as banking regulations change frequently.  
* **Solution:** The gem should provide easy access to these schema endpoints (e.g., Beneficiary.schema(country: 'US', currency: 'USD')). It acts as a conduit for the dynamic validation logic provided by the server, allowing the host application to build dynamic forms.

### **6.3. Foreign Exchange (FX)**

FX operations involve real-time rates and locking mechanisms.1

* **Rates vs. Quotes:** The gem must distinguish between getting a strict Rate (indicative) and creating a Quote (locked for a specific duration).  
* **Errors:** Specific errors like quote\_expired or insufficient\_funds are common.22 The gem should map these to specific exception classes to allow for programmatic handling (e.g., if a quote expires, automatically request a new one).

### **6.4. Issuing and Remote Authorization**

The Issuing API allows for creating cards and controlling spend. A key feature is **Remote Authorization**, where Airwallex asks the user's server to approve a transaction in real-time.23

* **Webhook Criticality:** This relies entirely on webhooks. The gem's webhook verification logic (discussed below) is critical here, as a forged authorization request could lead to fraudulent card spend.

## **7\. Data Models and Type Safety**

Financial APIs deal with precise data types. The gem must be rigorous in how it handles dates, currency, and numbers.

### **7.1. Date and Time Formats**

The research strictly identifies **ISO 8601** as the required format for dates and times.13

* **Requirement:** Fields like transfer\_date, conversion\_date, and from\_created\_at demand strings like "2023-10-27T10:00:00Z".  
* **Validation:** Error codes 025, 026, 027 correspond explicitly to invalid date formats.24  
* **Implementation:** The gem should accept standard Ruby Date and Time objects. The internal serializer must intercept these objects and format them to ISO 8601 strings (.iso8601) before transmission. This prevents the common "invalid format" errors that frustrate developers.

### **7.2. Currency and Monetary Values**

While the snippets don't explicitly detail decimal precision, financial APIs typically use either major units (10.50 USD) or minor units (1050 cents). The snippets show transaction\_amount as 11.11 27, implying **major units** (floats/decimals).

* **Risk:** Floating point math in Ruby (1.1 \+ 2.2\!= 3.3) is dangerous for finance.  
* **Gem Strategy:** The gem should encourage or enforce the use of BigDecimal for all monetary amounts to ensure precision is preserved during serialization and calculation.

## **8\. Webhook Integrity and Event Processing**

Webhooks are the nervous system of an Airwallex integration, notifying the app of asynchronous events (deposits, payout completions). Security here is paramount to prevent replay attacks or forged events.

### **8.1. Signature Verification**

The research confirms the use of **HMAC-SHA256** for signature verification.28

* **Headers:**  
  * x-timestamp: Unix timestamp of the event generation.  
  * x-signature: The hex digest.  
* **Algorithm:** The signature is generated by HMAC\_SHA256(secret, timestamp \+ body).29 Note the concatenation of timestamp and body.  
* **Timing Attack Prevention:** The gem must use a constant-time comparison algorithm (e.g., OpenSSL.secure\_compare) to check the signature. A simple string comparison (==) is vulnerable to timing attacks where an attacker can guess the signature byte-by-byte based on how long the comparison takes.

### **8.2. Replay Protection**

The gem must enforce a tolerance window for the x-timestamp.23

* **Logic:** Current Time \- Header Timestamp \< Tolerance.  
* **Standard:** A tolerance of 5 minutes (300 seconds) is standard industry practice.  
* If the timestamp is too old, the webhook should be rejected, even if the signature is valid. This prevents an attacker from capturing a valid request and replaying it later to confuse the system or trigger duplicate processing logic.

### **8.3. Event Object Construction**

The gem should factory Airwallex::Event objects from the JSON payload. Ideally, these objects should be immutable structs to prevent accidental modification during processing.

* **Properties:** id, type (e.g., payment\_intent.succeeded), data (the resource), created\_at.  
* **Parsing:** The data attribute should be parsed into the specific resource class (e.g., Airwallex::PaymentIntent), allowing methods like event.data.amount to work naturally, rather than forcing the developer to traverse a raw hash.

## **9\. Error Handling Architecture**

The robustness of a client library is defined by how it handles failure. The Airwallex API provides structured error information that the gem must parse and expose intelligibly.

### **9.1. HTTP Status Mapping**

The gem must map HTTP status codes to specific Exception classes 30:

* 400 \-\> Airwallex::BadRequestError: Malformed request, missing headers.  
* 401 \-\> Airwallex::AuthenticationError: Invalid API key, expired token.  
* 403 \-\> Airwallex::PermissionError: SCA required, insufficient scopes.  
* 404 \-\> Airwallex::NotFoundError: Resource not found.  
* 429 \-\> Airwallex::RateLimitError: Throttling active.  
* 500+ \-\> Airwallex::APIError: Server-side issues.

### **9.2. Error Body Polymorphism**

The error body structure is polymorphic, presenting a challenge for parsing.15 The gem must be able to handle all variations.

**Standard Error:**

JSON

{  
  "code": "insufficient\_fund",  
  "message": "The account has insufficient funds...",  
  "source": "charge"  
}

**Complex Error (with Details):**

JSON

{  
  "code": "request\_id\_duplicate",  
  "details": { "source\_id": "...", "source\_type": "..." },  
  "message": "request\_id '...' has been used..."  
}

**Validation Error (with Nested Source):**

JSON

{  
  "code": "invalid\_argument",  
  "message": "Type should be one of...",  
  "source": "individual.employers.business\_identifiers.type"  
}

Strategy:  
The base Airwallex::Error class must have attributes for code, message, param (mapped from source), and details. The initializer must inspect the JSON body and populate details only if it exists. This ensures that debugging complex validation errors (like a deeply nested field in a KYC object) is possible programmatically, without the developer needing to print and manually inspect the raw JSON response.

## **10\. Library Structure and Dependencies**

To align with the user's requirement for Ruby 3.1+, Rubocop, and Faraday, the following structural decisions are recommended.

### **10.1. Dependencies**

* **Runtime:**  
  * faraday (\~\> 2.0): The backbone of the HTTP transport.  
  * faraday-retry: Essential for implementing the exponential backoff logic for 429s and 5xx errors.  
  * json: Standard parsing.  
  * bigdecimal: For financial math.  
* **Development:**  
  * rubocop: Enforcing style guidelines. The configuration should be strict, enforcing typed signatures (RBS) where possible to leverage Ruby 3.1 capabilities.  
  * webmock / vcr: For recording and replaying API interactions during tests. This is crucial for testing complex flows like OAuth without needing a live browser or manually rotating keys.  
  * rspec: The standard testing framework.

### **10.2. Directory Structure**

A clean, modular structure is essential for maintainability.

lib/  
├── airwallex/  
│ ├── api\_operations/ \# Mixins for standard CRUD (Create, Retrieve, List)  
│ ├── resources/ \# Class definitions (Payment, Payout, Beneficiary)  
│ ├── errors.rb \# Exception hierarchy and mapping logic  
│ ├── client.rb \# The main HTTP entry point and configuration holder  
│ ├── webhook.rb \# Signature verification logic  
│ ├── util.rb \# Helpers for pagination, logging, and time formatting  
│ ├── middleware/ \# Custom Faraday middleware  
│ │ ├── auth\_refresh.rb \# Logic for lazy token refreshing  
│ │ └── idempotency.rb \# Logic for injecting request\_id  
│ └── version.rb  
└── airwallex.rb \# Configuration and module entry

### **10.3. The APIResource Pattern**

To reduce code duplication, the gem should implement an APIResource base class. Subclasses (e.g., Payment, Transfer) will inherit dynamic behavior.

* **Metaprogramming:** Use Ruby's method\_missing or define\_method to create accessors for JSON fields dynamically. This makes the gem resilient to API changes; if Airwallex adds a new field risk\_score, the gem supports it immediately without a version update. However, for known critical fields (like id, status), explicit accessors should be defined for better IDE autocompletion support.

## **11\. Conclusion**

Building the Airwallex Ruby gem requires navigating a sophisticated landscape of modern API patterns (Cursor pagination, HMAC webhooks) and strict financial constraints (ISO dates, strict idempotency). The blueprints provided here prioritize **safety and correctness**. By enforcing request\_id generation via middleware, handling the dual-pagination architectures with a unified abstraction, and managing the complex authentication flows transparently, the resulting gem will provide a stable foundation for Ruby developers to integrate global financial operations into their applications. The separation of environment configurations, robust error polymorphism handling, and adherence to SCA requirements ensures that the gem is not just a wrapper, but a piece of reliable financial infrastructure.

#### **Works cited**

1. Airwallex API Reference, accessed November 25, 2025, [https://www.airwallex.com/docs/api](https://www.airwallex.com/docs/api)  
2. Sandbox environment overview | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/developer-tools/sandbox-environment/sandbox-environment-overview](https://www.airwallex.com/docs/developer-tools/sandbox-environment/sandbox-environment-overview)  
3. Rate limits | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/developer-tools/api/rate-limits](https://www.airwallex.com/docs/developer-tools/api/rate-limits)  
4. Manage API keys | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/developer-tools/api/manage-api-keys](https://www.airwallex.com/docs/developer-tools/api/manage-api-keys)  
5. SCA for transaction data retrieval | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/payments-for-platforms/compliance-support/strong-customer-authentication-(sca)/sca-for-transaction-data-retrieval](https://www.airwallex.com/docs/payments-for-platforms/compliance-support/strong-customer-authentication-\(sca\)/sca-for-transaction-data-retrieval)  
6. Create a conversion | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/transactional-fx\_\_create-a-conversion](https://www.airwallex.com/docs/transactional-fx__create-a-conversion)  
7. Quickstart with Postman | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/developer-tools/api/quickstart-with-postman](https://www.airwallex.com/docs/developer-tools/api/quickstart-with-postman)  
8. Integration checklist | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/transactional-fx/test-and-go-live/integration-checklist](https://www.airwallex.com/docs/transactional-fx/test-and-go-live/integration-checklist)  
9. API | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/developer-tools/api](https://www.airwallex.com/docs/developer-tools/api)  
10. Native API | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/payments/online-payments/native-api](https://www.airwallex.com/docs/payments/online-payments/native-api)  
11. Existing customers | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/developer-tools/partner-connections/implement-your-authorization-flow/existing-customers](https://www.airwallex.com/docs/developer-tools/partner-connections/implement-your-authorization-flow/existing-customers)  
12. New Airwallex customers, accessed November 25, 2025, [https://www.airwallex.com/docs/developer-tools/partner-connections/implement-your-authorization-flow/new-airwallex-customers](https://www.airwallex.com/docs/developer-tools/partner-connections/implement-your-authorization-flow/new-airwallex-customers)  
13. Create a transfer | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/payouts\_\_create-a-transfer](https://www.airwallex.com/docs/payouts__create-a-transfer)  
14. Sample integration | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/billing/subscriptions/subscriptions-via-api/sample-integration](https://www.airwallex.com/docs/billing/subscriptions/subscriptions-via-api/sample-integration)  
15. Error codes | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/connected-accounts/move-funds/error-codes](https://www.airwallex.com/docs/connected-accounts/move-funds/error-codes)  
16. Error codes | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/global-treasury\_\_error-codes](https://www.airwallex.com/docs/global-treasury__error-codes)  
17. Server-side SDKs (Beta) | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/developer-tools/sdks/server-side-sdks-(beta)](https://www.airwallex.com/docs/developer-tools/sdks/server-side-sdks-\(beta\))  
18. Manage Global Accounts | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/global-treasury\_\_global-accounts\_\_manage-global-accounts](https://www.airwallex.com/docs/global-treasury__global-accounts__manage-global-accounts)  
19. 3D Secure authentication | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/payments/online-payments/native-api/3d-secure-authentication](https://www.airwallex.com/docs/payments/online-payments/native-api/3d-secure-authentication)  
20. Using API and form schemas | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/payments-for-platforms/pay-out-funds/using-api-and-form-schemas](https://www.airwallex.com/docs/payments-for-platforms/pay-out-funds/using-api-and-form-schemas)  
21. Using API and form schemas | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/payouts\_\_using-api-and-form-schemas](https://www.airwallex.com/docs/payouts__using-api-and-form-schemas)  
22. Error codes | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/transactional-fx\_\_error-codes](https://www.airwallex.com/docs/transactional-fx__error-codes)  
23. Respond to authorization requests | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/issuing\_\_remote-authorization\_\_respond-to-authorization-requests](https://www.airwallex.com/docs/issuing__remote-authorization__respond-to-authorization-requests)  
24. Transfer error codes | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/payouts/errors/transfer-error-codes](https://www.airwallex.com/docs/payouts/errors/transfer-error-codes)  
25. Error codes (older versions) | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/payouts\_\_transfers\_\_error-codes-(older-versions)](https://www.airwallex.com/docs/payouts__transfers__error-codes-\(older-versions\))  
26. Create a batch transfer | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/payouts/batch-transfers/create-a-batch-transfer](https://www.airwallex.com/docs/payouts/batch-transfers/create-a-batch-transfer)  
27. Respond to authorization requests | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/issuing/card-controls/remote-authorization/respond-to-authorization-requests](https://www.airwallex.com/docs/issuing/card-controls/remote-authorization/respond-to-authorization-requests)  
28. Listen for webhook events | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/developer-tools/webhooks/listen-for-webhook-events](https://www.airwallex.com/docs/developer-tools/webhooks/listen-for-webhook-events)  
29. Code examples | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/developer-tools/webhooks/listen-for-webhook-events/code-examples](https://www.airwallex.com/docs/developer-tools/webhooks/listen-for-webhook-events/code-examples)  
30. Error response codes | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/payments/troubleshooting/error-response-codes](https://www.airwallex.com/docs/payments/troubleshooting/error-response-codes)  
31. Error codes \- Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/issuing/troubleshooting/error-codes](https://www.airwallex.com/docs/issuing/troubleshooting/error-codes)