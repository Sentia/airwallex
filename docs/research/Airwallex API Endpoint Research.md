

# **Operational Architecture and Integration Strategy: A Deep Dive into the Airwallex API Ecosystem**

## **1\. Foundational Architecture and Design Philosophy**

The digitization of global financial infrastructure has necessitated a paradigm shift in how organizations interact with banking rails. The Airwallex API ecosystem represents a sophisticated abstraction layer over the heterogeneous and often archaic networks of international finance, such as SWIFT, SEPA, and local clearing systems. By unifying these disparately functioning networks into a cohesive, RESTful interface, Airwallex provides a programmable financial operating system designed for high-concurrency, global-scale operations. This report offers an exhaustive technical analysis of this ecosystem, dissecting its architectural principles, security protocols, domain-specific implementations, and integration patterns necessary for building robust financial applications.

### **1.1 RESTful Principles and Environment Segmentation**

At its core, the Airwallex API adheres to Representational State Transfer (REST) principles, prioritizing resource-oriented interactions that are stateless, cacheable, and predictable. This architectural choice lowers the cognitive load for developers, allowing for intuitive manipulation of resources—such as payments, beneficiaries, and accounts—using standard HTTP verbs (GET, POST, PATCH, DELETE). The platform enforces a rigorous separation of concerns through distinct environments, preventing the contamination of production ledgers with test data.

The API operates across two primary environments, differentiated at the subdomain level to ensure isolation. The **Sandbox environment**, accessible via https://api-demo.airwallex.com/api/v1/, serves as a fully functional simulation ground.1 Here, developers can emulate complex financial scenarios—including KYC approvals, settlement delays, and transaction failures—without moving real funds. This environment is crucial for stress testing and validating logic paths that are difficult to reproduce in a live setting, such as 3D Secure challenges or specific issuer decline codes. Conversely, the **Production environment**, located at https://api.airwallex.com/api/v1/, is the live transactional gateway where real value transfer occurs.1 The strict bifurcation of these environments extends to credential management, requiring distinct sets of API keys and client identifiers for each, thereby mitigating the risk of accidental real-world transactions during development cycles.2

### **1.2 Versioning Strategy and API Evolution**

In the rapidly evolving landscape of fintech, API stability is paramount. Airwallex addresses this through a date-based versioning strategy (e.g., 2024-09-27 or 2025-11-11), which allows the platform to introduce backward-incompatible changes—such as field renaming or structural modifications—without disrupting active integrations.1 This versioning is immutable; once a version is locked for an account, the API behavior remains consistent regardless of newer releases.

Clients can manage their API version through the Airwallex web app or, for testing migration paths, override the account-level setting on a per-request basis using the x-api-version header.4 This capability is particularly valuable for regression testing, allowing teams to validate their application against a newer API specification in the Sandbox environment before committing to a global upgrade. The documentation highlights that recent versions have introduced significant structural improvements, such as the consolidation of payment and transfer resources and the renaming of legacy endpoints to better reflect their function, underscoring the importance of staying current with the changelog.1

### **1.3 High-Concurrency Request Management**

Financial systems must handle bursts of activity without compromising data integrity. The Airwallex API is designed to support high-volume operations, enforcing rate limits to ensure platform stability. In the production environment, the global rate limit is set to 100 requests per second, with specific endpoints capped at 20 requests per second.5 To prevent a single account from monopolizing resources, a concurrency limit of 50 simultaneous requests is enforced.

Beyond simple rate limiting, the architecture employs sophisticated queueing and throttling mechanisms. When limits are exceeded, the API responds with a 429 Too Many Requests status code. Robust integration strategies must implement exponential backoff algorithms to handle these responses gracefully, ensuring that temporary spikes in traffic do not result in data loss or transaction failures. The platform’s capacity to handle 100 operations per second suggests a highly scalable backend capable of supporting enterprise-level marketplaces and platforms with significant transaction throughput.5

## **2\. Security Protocols and Identity Management**

Security in financial APIs is not merely a feature but a foundational constraint. Airwallex employs a multi-layered security model centered on OAuth2 standards, ensuring that access is strictly controlled, auditable, and revocable. This section analyzes the authentication lifecycle and the mechanisms for securing data in transit.

### **2.1 Bearer Token Authentication Lifecycle**

The primary mechanism for API access is the Bearer Token authentication scheme. Unlike systems that rely solely on long-lived API keys sent with every request—a practice that increases the attack surface if keys are intercepted—Airwallex uses long-term credentials to generate short-lived access tokens.

The authentication flow begins with a credential exchange. The client application sends a POST request to the /api/v1/authentication/login endpoint, providing the x-client-id and x-api-key in the headers.1 Upon validation, the server issues a JSON Web Token (JWT) with a defined expiration (typically 30 minutes to an hour).

**Table 1: Authentication Headers and Parameters**

| Header Name | Description | Usage Context |
| :---- | :---- | :---- |
| x-client-id | Unique identifier for the API client. | Required for initial token generation 6. |
| x-api-key | Secret key associated with the client ID. | Required for initial token generation 6. |
| Authorization | The Bearer token (JWT). | Required for all subsequent API requests 1. |

This token must be included in the Authorization header (e.g., Authorization: Bearer \<token\>) for all subsequent resource interactions. The short lifespan of these tokens necessitates a robust token management strategy within the client application, including automatic refresh logic to prevent service interruptions.1

### **2.2 Granular Access Control: Scoped vs. Admin Keys**

Airwallex distinguishes between "Admin" and "Scoped" API keys, enforcing the principle of least privilege. Admin keys grant unrestricted access to the entire organization's resources, making them suitable for initial setup or "God-mode" administrative scripts but inherently risky for day-to-day operations.6 If an Admin key is compromised, the attacker gains full control over funds and data.

Scoped API keys mitigate this risk by encapsulating specific permissions. An administrator can generate a key that is strictly limited to read-only access for reporting, or write-only access for generating payment links, without the ability to withdraw funds. This granular control is essential for microservices architectures where different services require different levels of access. For instance, a reporting service need not—and should not—have the authority to execute payouts. The API allows the creation of these scoped keys via the developer settings in the web app, providing a secure mechanism for distributing access across a development team or partner ecosystem.6

### **2.3 Multi-Tenancy and the x-login-as Header**

For platforms managing complex organizational hierarchies or transacting on behalf of multiple business units, context switching is a critical requirement. Airwallex facilitates this via the x-login-as header. This header allows a client authenticated with organization-level credentials to "impersonate" or target a specific sub-account without re-authenticating.6

The behavior of x-login-as is nuanced:

* **Multiple Accounts:** If a scoped key is linked to multiple accounts, the header is mandatory to specify which account context the request applies to.  
* **Org and Account Access:** If the key has both organization and account-level scope, the header is optional; omitting it defaults to the organization context.  
* **Single Account:** If the key is scoped to a single account, the header is unnecessary as the context is implied.6

This mechanism is particularly powerful for SaaS platforms and marketplaces that act as the system of record for their users, allowing them to seamlessly switch between user contexts to manage funds, generate reports, or configure settings programmatically.

### **2.4 Idempotency and Data Integrity**

In distributed systems, network failures are inevitable. A request to create a payment might timeout before the client receives a response, leaving the state of the transaction unknown. Retrying such a request without protection could lead to double-charging a customer or duplicate payouts. Airwallex resolves this through **idempotency keys**.

The API supports a unique identifier, often passed via the request\_id field in the request body or implicitly handled via headers in some SDK implementations, to enforce idempotency.7 When a request includes a request\_id that has already been processed, the API does not re-execute the logic; instead, it returns the original response. This ensures that operations like POST /transfers/create or POST /payment\_intents/create are safe to retry.9

**Best Practice:** Developers should generate a UUID v4 for every mutation request and persist this key. In the event of a network error (e.g., a 500 or timeout), the application should retry the request with the *same* request\_id. If the server had successfully processed the initial request, it will return the successful payload; if not, it will process the retry as a new request. This guarantees exactly-once processing semantics for critical financial operations.7

## **3\. The Payment Acceptance Engine (Acquiring)**

The Payment Acceptance (PA) domain governs the inbound flow of funds, allowing merchants to accept payments via cards, digital wallets, and local payment methods. The architecture centers on the **Payment Intent**, a stateful resource that tracks the lifecycle of a transaction from initiation to settlement.

### **3.1 The Payment Intent Lifecycle**

Unlike simpler APIs that might use a single "charge" call, Airwallex employs a two-step process involving the creation and confirmation of a Payment Intent. This separation allows for complex workflows involving asynchronous authentication (like 3D Secure) and "late" binding of payment details.

#### **3.1.1 Initialization**

The process begins with the creation of a Payment Intent using POST /api/v1/pa/payment\_intents/create. This establishes the session parameters, such as the amount, currency, and order reference.10

**Endpoint:** POST /api/v1/pa/payment\_intents/create

**Key Payload Attributes:**

* amount: The precise value to be captured.  
* currency: The 3-letter ISO 4217 code (e.g., USD, HKD).  
* merchant\_order\_id: A reconciliation key linking the payment to the merchant's internal database.  
* return\_url: The URL where the customer is redirected after external authentication (critical for 3DS and APMs).12

**Strategic Insight:** By creating the intent server-side, the merchant locks in the commercial terms of the transaction before any sensitive payment data is collected on the client side. This prevents malicious manipulation of amounts or currencies by the end-user.

#### **3.1.2 Confirmation and Authorization**

Once the intent is created and the client\_secret or id is passed to the frontend, the payment details are collected. The intent is then "confirmed" via POST /api/v1/pa/payment\_intents/{id}/confirm. This step triggers the actual communication with the card networks or payment schemes.10

The confirmation payload is polymorphic, changing based on the payment method:

* **Card Payments:** Requires encrypted card data or a reference to a payment\_method\_id.10  
* **Digital Wallets:** For Apple Pay or Google Pay, the encrypted payment token generated by the device is passed directly. The integration requires specific handling of the encrypted\_payment\_token blob.10  
* **Redirect Methods:** For methods like Alipay or Bancontact, the response to the confirmation request will include a next\_action object containing a URL. The client must redirect the user to this URL to complete the payment.12

### **3.2 Native vs. Hosted Integration**

Airwallex offers distinct integration paths balancing control versus ease of implementation. The **Native API** offers complete control over the UI/UX, allowing merchants to render their own forms and handle the entire checkout flow programmatically. This requires a higher level of PCI compliance (SAQ D) but provides a seamless, white-labeled experience.16

For the Native API, specific steps are required for wallets like Google Pay. The merchant must handle the isReadyToPay check and the LoadPaymentData call on the frontend, then pass the resulting token to the Airwallex backend. The configuration involves specifying gateway: airwallex and the gatewayMerchantId (the account ID) in the Google Pay payload.15

Conversely, the **Embedded Elements** or Hosted Payment Page offload the PCI burden and UI rendering to Airwallex, using IFrames or redirection. The research indicates that while the Native API offers flexibility, it also mandates the integration of the Airwallex Risk SDK to satisfy regulatory requirements and fraud prevention measures.4

### **3.3 Payment Methods and Dynamic Configuration**

The global payment landscape is fragmented. Airwallex supports a vast array of local methods (LPMs) alongside major card networks. To manage this complexity, the API provides configuration endpoints (e.g., /api/v1/pa/config/payment\_method\_types) that allow developers to dynamically query available payment methods based on the customer's region and currency.17

**Table 2: Supported Payment Method Categories**

| Category | Examples | API Behavior |
| :---- | :---- | :---- |
| **Cards** | Visa, Mastercard, Amex, JCB, UnionPay | Synchronous authorization; supports 3DS. 17 |
| **Digital Wallets** | Apple Pay, Google Pay, WeChat Pay, AliPay | Requires token decryption; often involves mobile SDKs. 15 |
| **Bank Transfers** | PayNow (SG), PromptPay (TH) | Asynchronous; relies on webhooks for success confirmation. \[18\] |
| **Local APMs** | iDEAL, Bancontact, Klarna | Typically requires redirecting the user to the provider's portal. \[19\] |

This dynamic querying capability is essential for "Smart Checkout" implementations, where the payment options presented to the user are filtered in real-time to show only those relevant to their geolocation and order context.

## **4\. Global Payouts and Treasury Management**

The Payouts domain facilitates the movement of funds from the Airwallex ecosystem to external beneficiaries. This is the engine behind marketplace seller payouts, payroll distribution, and vendor payments. The architecture is designed to optimize for speed and cost by intelligently routing funds through local clearing systems whenever possible.

### **4.1 The Transfer Resource**

The primary resource for moving money is the **Transfer**. The API has recently consolidated various payment endpoints into a unified POST /api/v1/transfers/create interface, streamlining the integration process.20

**Endpoint:** POST /api/v1/transfers/create

**Critical Attributes:**

* transfer\_method: The routing mechanism. LOCAL utilizes domestic clearing networks (e.g., ACH in US, FPS in UK, SEPA in EU), offering faster settlements and lower fees. SWIFT utilizes the international correspondent banking network, necessary for cross-border payments where no local route exists.20  
* source\_currency vs. payment\_currency: If these differ (e.g., sourcing USD to pay in EUR), the API automatically executes an FX conversion as part of the transfer logic.20  
* beneficiary\_id: A reference to a stored beneficiary entity.

**Deep Insight \- FX Integration:** The integration of FX into the transfer endpoint simplifies the workflow for cross-border payments. Instead of booking a separate conversion and then a transfer, the API handles the atomic operation. For advanced treasury use cases, a quote\_id can be passed to the transfer request. This ties the transfer to a previously locked exchange rate, ensuring zero slippage between the time the quote was displayed to the user and the moment the funds move.22

### **4.2 The Dynamic Schema Engine**

One of the most significant challenges in global payouts is data validation. Banking requirements vary wildly: the US requires a 9-digit Routing Number, the UK requires a Sort Code, and Europe requires an IBAN. Hardcoding these rules is prone to error. Airwallex addresses this with a **Dynamic Schema API**.

**Endpoint:** GET /api/v1/beneficiaries/schema

Developers can query this endpoint with parameters like bank\_country\_code and transfer\_method (e.g., CN and LOCAL). The API responds with a JSON schema defining exactly which fields are required (e.g., "Alphanumeric, 8-11 characters" for a SWIFT code) and provides regex patterns for validation.21

**Implication:** This allows frontend applications to dynamically render beneficiary forms. Instead of maintaining a massive library of banking rules, the UI simply renders the fields dictated by the API schema for the selected country. This decoupling ensures that the application automatically supports new corridors or regulatory changes without code deployments.24

### **4.3 Batch Transfers**

For high-volume operations like payroll, initiating individual HTTP requests for thousands of employees is inefficient and risks hitting rate limits. The **Batch Transfer API** allows clients to submit up to 1000 payment instructions in a single payload.

**Endpoint:** POST /api/v1/batch\_transfers/create

The processing of a batch is asynchronous. The response acknowledges the receipt of the batch and provides a batch\_id. The client must then poll the status endpoint or, more preferably, listen for webhooks to track the completion of the batch and the status of individual items within it.26

## **5\. Global Accounts and Virtual Collections**

Global Accounts allow businesses to collect funds locally in various currencies, effectively providing local bank details (Virtual IBANs) in multiple jurisdictions.

### **5.1 Account Provisioning**

The provisioning of these accounts is programmatic, enabling platforms to issue unique bank details to each of their customers.

**Endpoint:** POST /api/v1/global\_accounts/create

**Parameters:**

* country\_code: The jurisdiction (e.g., US, GB, AU).  
* nick\_name: An internal identifier.  
* required\_features: Specifies the needed capabilities, such as transfer\_method: "LOCAL" or transfer\_method: "SWIFT".29

The response returns a complete set of banking coordinates: Account Name, Account Number, Routing Code (ABA, Sort Code, BSB), and Bank Address. These details can be embedded directly into invoices.31

### **5.2 Multi-Currency Capabilities**

Recent updates to the API have introduced **Multi-currency Global Accounts**. This architectural enhancement allows a single set of banking details (e.g., a UK account number) to receive funds in multiple currencies if supported by the underlying banking partner. This dramatically simplifies the reconciliation process, as a merchant needs to manage fewer account entities while still accepting diverse currencies.1

### **5.3 Reconciliation**

**Endpoint:** GET /api/v1/global\_accounts/{id}/transactions

For platforms tracking incoming payments, this endpoint acts as the ledger. It provides detailed information on the sender (remitter), the amount, and the reference field. This granularity is essential for automated reconciliation systems that match incoming deposits to open invoices.31

## **6\. Card Issuing and Spend Management**

The Issuing API transforms the client into a card issuer, capable of generating virtual and physical Visa/Mastercards. This is widely used for expense management, supplier payments, and disbursement cards.

### **6.1 Card Lifecycle Management**

**Endpoint:** POST /api/v1/issuing/cards/create

Cards can be issued to an ORGANISATION (for general business expenses) or an INDIVIDUAL (requiring a linked Cardholder object with KYC data). The form\_factor parameter dictates whether the card is VIRTUAL (instantly active) or PHYSICAL (shipped to an address).32

**Security Note:** Upon creation, the API does not return the full Primary Account Number (PAN) or CVV in the clear for PCI compliance reasons. These sensitive details must be retrieved via a dedicated PCI-compliant endpoint (GET /api/v1/issuing/cards/{id}/details), often requiring the frontend to render the data inside a secure iframe or for the backend to possess PCI DSS certification.1

### **6.2 Remote Authorization (Just-in-Time Funding)**

A distinguishing feature of the Airwallex Issuing platform is **Remote Authorization**. This capability allows the client to participate in the transaction approval loop in real-time.

**Mechanism:**

1. A transaction is attempted on an issued card.  
2. Airwallex sends a synchronous webhook (issuing.authorization.request) to the client's configured endpoint.  
3. The client's server evaluates the request logic (e.g., checking if the merchant category code matches the employee's travel policy, or if the specific budget has funds).  
4. The client responds with an APPROVE or DECLINE decision.

This entire loop must complete within a tight timeframe (milliseconds) to avoid timeouts at the point of sale. It enables sophisticated spend controls that go far beyond static limits.34

**Signature Verification:** To ensure these requests genuinely originate from Airwallex, the x-signature and x-nonce headers are used. The client must verify the HMAC-SHA256 signature of the payload using their shared secret.34

## **7\. Transactional FX and Liquidity**

While FX is often implicit in transfers, the Transactional FX API exposes the core trading engine for explicit currency management.

### **7.1 LockFX vs. MarketFX**

The API offers two primary mechanisms for currency conversion:

1. **MarketFX:** Executed at the current available market rate. Useful for immediate internal conversions where exact rate certainty is secondary to execution speed.  
   * **Endpoint:** POST /api/v1/fx/conversions/create (without a quote ID).36  
2. **LockFX (Quotes):** Guarantees a specific rate for a defined window. This is critical for platforms that display a price to a user (e.g., a travel site showing hotel prices in a local currency). The platform can lock the rate when the user views the price, ensuring the margin is protected even if the user takes 15 minutes to complete the checkout.  
   * **Endpoint:** POST /api/v1/fx/quotes/create  
   * **Usage:** The response includes a quote\_id which is valid for a duration (e.g., 15 minutes, 24 hours). This ID is then passed to the conversion or transfer endpoint to execute the trade at the agreed price.37

### **7.2 Streaming Rates**

**Endpoint:** GET /api/v1/fx/rates/current

For applications needing to display indicative pricing tickers, this endpoint provides real-time exchange rates. It supports querying specific currency pairs (buy\_currency, sell\_currency) to get the current mid-market or client rate.36

## **8\. Platform Architecture: The Scale API**

For SaaS platforms and marketplaces, Airwallex provides the "Scale" suite, enabling the creation and management of sub-accounts (Connected Accounts).

### **8.1 Connected Accounts and Onboarding**

Platforms can create accounts for their users programmatically.

**Endpoint:** POST /api/v1/accounts/create

This creates a "shell" account. To become operational, the account must undergo Know Your Customer (KYC) or Know Your Business (KYB) verification. Airwallex offers two paths for this:

* **Hosted Flow:** The platform requests a URL and redirects the user to an Airwallex-hosted form to upload documents. This is the fastest integration path.  
* **Native API:** The platform collects the data (Beneficial Owners, Business Registration) via its own UI and submits it via POST /api/v1/accounts/{id}/submit. This offers a fully white-labeled experience but requires the platform to handle sensitive PII.39

### **8.2 The x-on-behalf-of Header**

The architectural linchpin of the Scale offering is the x-on-behalf-of header. When a platform authenticates with its master token, it can inject this header containing the account\_id of a connected account.

**Usage:**

* POST /api/v1/transfers/create \+ x-on-behalf-of: acct\_123  
* **Effect:** The transfer is executed *from* the wallet of acct\_123, not the platform's own wallet.

This mechanism allows the platform to orchestrate the entire financial life of its users—moving funds, issuing cards, and converting currency—without managing credentials for each user.6

### **8.3 Application Fees**

Monetization is built directly into the API. Platforms can attach application\_fee parameters to transactions. For example, when a connected account receives a payment or executes a conversion, the platform can strip a fee (e.g., 0.5%) which is automatically routed to the platform's revenue wallet.42

## **9\. Event-Driven Architecture and Webhooks**

Given the asynchronous nature of financial settlement (which can take days), polling APIs for status updates is inefficient and prone to rate limiting. Airwallex relies on a robust webhook architecture to push state changes to the client.

### **9.1 Webhook Configuration**

**Endpoint:** POST /api/v1/webhooks/create

Webhooks can be configured to listen to specific events (e.g., payment\_intent.succeeded, payout.transfer.failed). The platform supports IP whitelisting to ensure security. In the **Production environment**, webhooks originate from a specific set of IPs (e.g., 35.240.218.67, 35.185.179.53, 34.87.64.173), which clients should allow through their firewalls.43

### **9.2 Security: Signature Verification**

To prevent replay attacks and ensure payload integrity, Airwallex signs every webhook event. The headers include:

* x-timestamp: The time the event was sent.  
* x-signature: An HMAC-SHA256 hash of the payload.43

Verification Logic:  
The receiver must construct a string by concatenating the x-timestamp and the raw JSON body of the request. This string is then hashed using the webhook secret (provided at creation) and SHA-256. The resulting hash must match the x-signature header exactly.43

### **9.3 Critical Event Types**

**Table 3: Essential Webhook Events**

| Event Type | Trigger | Action Required |
| :---- | :---- | :---- |
| payment\_intent.succeeded | Customer payment captured. | Release goods/service to customer. \[44\] |
| payout.transfer.failed | Outbound transfer rejected. | Notify user; funds returned to wallet. \[45\] |
| account.status\_changed | KYC approved/rejected. | Update user status in platform DB. \[46\] |
| issuing.authorization.request | Card swiped at terminal. | Approve/Decline transaction logic. 34 |

## **10\. Operational Resilience and Error Handling**

Building resilient financial systems requires anticipating failure. This section covers the strategies for handling errors and maintaining consistency.

### **10.1 HTTP Status Codes and Error Payloads**

Airwallex uses standard HTTP codes to indicate success or failure.

* **200/201:** Success.  
* **400 Bad Request:** Validation error (e.g., invalid IBAN). The response body will contain a code (e.g., validation\_failed) and a message detailing the specific field error.7  
* **401 Unauthorized:** Invalid token.  
* **429 Too Many Requests:** Rate limit exceeded.  
* **500 Internal Server Error:** Platform-side failure.

**Specific Error Codes:**

* insufficient\_funds: The wallet lacks the balance to cover the transfer/conversion.7  
* bank\_account\_suspended: The destination or source account is frozen.  
* cancellation\_failed: The transfer has already progressed too far to be cancelled.47

### **10.2 Integration with Ruby and Faraday**

The research highlights specific patterns for integrating Airwallex using Ruby and the Faraday HTTP client library. Since Airwallex relies heavily on headers for idempotency (request\_id) and context (x-on-behalf-of), configuring the Faraday middleware stack is critical.

Middleware Configuration:  
Developers should configure Faraday to handle the Authorization header using Bearer authentication. Snippets suggest using faraday\_middleware for JSON parsing (FaradayMiddleware::ParseJson) to automatically deserialize response bodies. Crucially, retry logic should be implemented using Faraday::Request::Retry to handle intermittent network failures (idempotent methods only), ensuring that a temporary connection drop doesn't result in a hard failure for the user.48

### **10.3 Simulation and Magic Values**

To facilitate testing, the Sandbox environment supports "Magic Values." These are specific data inputs that trigger predetermined behaviors, allowing developers to test edge cases that are hard to replicate naturally.

**Table 4: Sandbox Simulation Triggers**

| Trigger | Value/Action | Outcome |
| :---- | :---- | :---- |
| **3DS Challenge** | Amount $88.88 | Triggers a 3D Secure challenge flow \[51\]. |
| **Card Decline** | Amount $88.88 (specific cards) | Simulates an issuer decline \[51\]. |
| **KYC Review** | Submit account | Can simulate manual review delays \[39\]. |
| **Status Transition** | POST /simulation/transfers/transition | Force a transfer from PROCESSING to FAILED \[52\]. |

## **11\. Conclusion**

The Airwallex API represents a high-fidelity abstraction of the global financial system. Its strength lies in the consistent application of RESTful design patterns across disparate domains—from card issuing to SWIFT transfers. For architects and developers, the critical path to success involves a deep understanding of the "Scale" architecture (x-on-behalf-of), the strict adherence to the Dynamic Schema for payouts, and the implementation of robust, idempotent retry logic. By leveraging the extensive simulation capabilities and adhering to the security protocols outlined in this report, organizations can build financial infrastructure that is both globally scalable and operationally resilient.

## **Appendix: Comprehensive Endpoint Summary**

| Domain | Method | Path | Functional Description |
| :---- | :---- | :---- | :---- |
| **Auth** | POST | /authentication/login | Exchange API credentials for a Bearer Token. |
| **Payments** | POST | /pa/payment\_intents/create | Initialize a payment session (stateful). |
| **Payments** | POST | /pa/payment\_intents/{id}/confirm | Execute authorization; payload varies by method. |
| **Payouts** | POST | /transfers/create | Execute a single payout (Bank or Wallet). |
| **Payouts** | GET | /beneficiaries/schema | Retrieve validation rules for bank details. |
| **Accounts** | POST | /global\_accounts/create | Provision a virtual collection account. |
| **FX** | GET | /fx/rates/current | Streaming exchange rates for display. |
| **FX** | POST | /fx/quotes/create | Lock an FX rate for a specific duration. |
| **FX** | POST | /fx/conversions/create | Execute a currency trade (Spot or LockFX). |
| **Issuing** | POST | /issuing/cards/create | Issue a virtual or physical card. |
| **Issuing** | GET | /issuing/cards/{id}/details | PCI-secure retrieval of PAN/CVV. |
| **Scale** | POST | /accounts/create | Create a Connected Account container. |
| **Scale** | POST | /accounts/{id}/submit | Trigger KYC/KYB verification process. |
| **Webhooks** | POST | /webhooks/create | Register a URL to receive event notifications. |

#### **Works cited**

1. Airwallex API Reference, accessed November 25, 2025, [https://www.airwallex.com/docs/api](https://www.airwallex.com/docs/api)  
2. Sandbox environment overview | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/developer-tools/sandbox-environment/sandbox-environment-overview](https://www.airwallex.com/docs/developer-tools/sandbox-environment/sandbox-environment-overview)  
3. API | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/developer-tools/api](https://www.airwallex.com/docs/developer-tools/api)  
4. Native API | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/payments/online-payments/native-api](https://www.airwallex.com/docs/payments/online-payments/native-api)  
5. Rate limits | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/developer-tools/api/rate-limits](https://www.airwallex.com/docs/developer-tools/api/rate-limits)  
6. Manage API keys | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/developer-tools/api/manage-api-keys](https://www.airwallex.com/docs/developer-tools/api/manage-api-keys)  
7. Error codes | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/connected-accounts/move-funds/error-codes](https://www.airwallex.com/docs/connected-accounts/move-funds/error-codes)  
8. Idempotency-Key header \- HTTP \- MDN Web Docs, accessed November 25, 2025, [https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Idempotency-Key](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Idempotency-Key)  
9. Sample integration | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/billing/subscriptions/subscriptions-via-api/sample-integration](https://www.airwallex.com/docs/billing/subscriptions/subscriptions-via-api/sample-integration)  
10. Native API | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/payments/payment-methods/global/apple-pay/native-api](https://www.airwallex.com/docs/payments/payment-methods/global/apple-pay/native-api)  
11. Get started with online payments | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/payments\_\_get-started-with-online-payments](https://www.airwallex.com/docs/payments__get-started-with-online-payments)  
12. Desktop/Mobile Website Browser \- Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/payments/payment-methods/eu-and-uk/mybank/desktopmobile-website-browser](https://www.airwallex.com/docs/payments/payment-methods/eu-and-uk/mybank/desktopmobile-website-browser)  
13. Desktop/Mobile Website Browser \- Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/payments/payment-methods/eu-and-uk/lithuanian-banks/desktopmobile-website-browser](https://www.airwallex.com/docs/payments/payment-methods/eu-and-uk/lithuanian-banks/desktopmobile-website-browser)  
14. Guest user checkout | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/payments/online-payments/native-api/guest-user-checkout](https://www.airwallex.com/docs/payments/online-payments/native-api/guest-user-checkout)  
15. Native API | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/payments/payment-methods/global/google-paytm/native-api](https://www.airwallex.com/docs/payments/payment-methods/global/google-paytm/native-api)  
16. 3D Secure authentication | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/payments/online-payments/native-api/3d-secure-authentication](https://www.airwallex.com/docs/payments/online-payments/native-api/3d-secure-authentication)  
17. Payment methods overview | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/payments/payment-methods/payment-methods-overview](https://www.airwallex.com/docs/payments/payment-methods/payment-methods-overview)  
18. Create a transfer | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/payouts\_\_create-a-transfer](https://www.airwallex.com/docs/payouts__create-a-transfer)  
19. Using API and form schemas | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/payments-for-platforms/pay-out-funds/using-api-and-form-schemas](https://www.airwallex.com/docs/payments-for-platforms/pay-out-funds/using-api-and-form-schemas)  
20. Create a transfer \- Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/payments-for-platforms/pay-out-funds/create-a-transfer](https://www.airwallex.com/docs/payments-for-platforms/pay-out-funds/create-a-transfer)  
21. Retrieve beneficiaries | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/payouts\_\_retrieve-beneficiaries](https://www.airwallex.com/docs/payouts__retrieve-beneficiaries)  
22. Using API and form schemas | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/payouts\_\_using-api-and-form-schemas](https://www.airwallex.com/docs/payouts__using-api-and-form-schemas)  
23. Embedded Beneficiary component | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/payouts/beneficiaries/embedded-beneficiary-component](https://www.airwallex.com/docs/payouts/beneficiaries/embedded-beneficiary-component)  
24. Create a batch transfer | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/payouts/batch-transfers/create-a-batch-transfer](https://www.airwallex.com/docs/payouts/batch-transfers/create-a-batch-transfer)  
25. Create a batch transfer | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/payouts\_\_create-a-batch-transfer](https://www.airwallex.com/docs/payouts__create-a-batch-transfer)  
26. Retrieve batch transfers | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/payouts\_\_retrieve-batch-transfers](https://www.airwallex.com/docs/payouts__retrieve-batch-transfers)  
27. Create Global Accounts | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/banking-as-a-service\_\_create-global-accounts](https://www.airwallex.com/docs/banking-as-a-service__create-global-accounts)  
28. Global Accounts | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/global-treasury\_\_global-accounts](https://www.airwallex.com/docs/global-treasury__global-accounts)  
29. Simulate deposits to your Global Account \- Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/global-treasury/receive-funds/receive-bank-transfers-to-global-accounts/simulate-deposits-to-your-global-account](https://www.airwallex.com/docs/global-treasury/receive-funds/receive-bank-transfers-to-global-accounts/simulate-deposits-to-your-global-account)  
30. Create individual cards (older API versions) | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/issuing\_\_create-a-card-(older-api-versions)\_\_create-individual-cards-(older-api-versions)](https://www.airwallex.com/docs/issuing__create-a-card-\(older-api-versions\)__create-individual-cards-\(older-api-versions\))  
31. Create a card (older API versions) | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/issuing/legacy-issuing-apis/create-a-card-(older-api-versions)](https://www.airwallex.com/docs/issuing/legacy-issuing-apis/create-a-card-\(older-api-versions\))  
32. Respond to authorization requests | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/issuing\_\_remote-authorization\_\_respond-to-authorization-requests](https://www.airwallex.com/docs/issuing__remote-authorization__respond-to-authorization-requests)  
33. Respond to authorization requests | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/issuing/card-controls/remote-authorization/respond-to-authorization-requests](https://www.airwallex.com/docs/issuing/card-controls/remote-authorization/respond-to-authorization-requests)  
34. Create a conversion | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/transactional-fx\_\_create-a-conversion](https://www.airwallex.com/docs/transactional-fx__create-a-conversion)  
35. Quotes | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/transactional-fx\_\_choose-your-fx-solution\_\_quotes](https://www.airwallex.com/docs/transactional-fx__choose-your-fx-solution__quotes)  
36. Choose your FX solution | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/transactional-fx\_\_choose-your-fx-solution](https://www.airwallex.com/docs/transactional-fx__choose-your-fx-solution)  
37. Simulate connected account status transition \- Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/developer-tools/sandbox-environment/connected-accounts/simulate-connected-account-status-transition](https://www.airwallex.com/docs/developer-tools/sandbox-environment/connected-accounts/simulate-connected-account-status-transition)  
38. Native API \- Create connected accounts \- Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/banking-as-a-service/connected-accounts/kyc-and-onboarding/native-api](https://www.airwallex.com/docs/banking-as-a-service/connected-accounts/kyc-and-onboarding/native-api)  
39. Connected accounts overview | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/banking-as-a-service\_\_connected-accounts-overview](https://www.airwallex.com/docs/banking-as-a-service__connected-accounts-overview)  
40. Application fees \- Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/global-treasury/revenue-and-fees/application-fees](https://www.airwallex.com/docs/global-treasury/revenue-and-fees/application-fees)  
41. Listen for webhook events | Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/developer-tools/webhooks/listen-for-webhook-events](https://www.airwallex.com/docs/developer-tools/webhooks/listen-for-webhook-events)  
42. Handle failed transfers \- Airwallex Docs, accessed November 25, 2025, [https://www.airwallex.com/docs/payouts/transfers/manage-transfers/handle-failed-transfers](https://www.airwallex.com/docs/payouts/transfers/manage-transfers/handle-failed-transfers)  
43. Faraday Docs \- GitHub Pages, accessed November 25, 2025, [https://lostisland.github.io/faraday/](https://lostisland.github.io/faraday/)  
44. lostisland/faraday-retry: Catches exceptions and retries each request a limited number of times \- GitHub, accessed November 25, 2025, [https://github.com/lostisland/faraday-retry](https://github.com/lostisland/faraday-retry)  
45. Implementing Faraday Retry in Rails, accessed November 25, 2025, [http://snags88.github.io/implementing-faraday-retry-in-rails](http://snags88.github.io/implementing-faraday-retry-in-rails)