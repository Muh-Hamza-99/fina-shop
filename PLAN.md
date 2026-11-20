# Final, Ultra-Detailed Technical Design Document: Fina Shops (Rails 8 Architecture)

**Document Version:** Final v3.0 (Fine-Tuned for FinaX Wholesale + POS Growth Demo)

**Target Stack:** Ruby on Rails 8+ · PostgreSQL 17 · Solid Queue / Solid Cache / Solid Cable · Hotwire (Turbo + Stimulus) · Kamal 2

**Deployment Target:** Single self-hosted VM (2 vCPU / 4 GB RAM, 40–80 GB NVMe SSD) + S3/R2/MinIO Object Storage

**Currency & Locale Baseline:** Saudi Riyal (`SAR`, stored as integer **halalas**, `1 SAR = 100 halalas`), bilingual **Arabic (`ar`, RTL)** and **English (`en`, LTR)**, 15% Saudi VAT, ZATCA readiness

---

## 1. Strategic Context & Why This Architecture Wins for FinaX

Inspection of the `fina.shop` merchant admin (such as `elshohail.fina.shop`, dated Friday, November 20, 2026) highlights an early-stage B2B wholesale catalog and quote-request shell (`Dashboard`, `Products`, `Categories`, `Quote Requests`, `Customers`, `Analytics`, `Customize Theme`, `Store Settings`, `Billing & Subscription`, `Settings`) with clear friction points:

* **RFQ-First Wholesale Model:** Buyers submit quote requests rather than checking out blindly on commercial/bulk SKUs (e.g., commercial mixers and ovens priced in SAR), moving through stages like `New`, `Viewed`, `Quotations Sent`, `Negotiation`, `Accepted`, `Paid`, and `Completed`.


* **Data & Onboarding Rough Edges:** Imported products have had missing prices (`Single-layer electric oven, single tray, home use` showing `-` price), categories can start empty (`No categories`), e-invoicing starts `Inactive`, `Show Prices` can default to hidden, and a `No Active Subscription` / `Start Free Trial` banner sits prominently in billing.


* **FinaX Growth Mandate:** Rather than building an over-engineered Shopify clone, **Fina Shops** should be a **fast, self-hosted wholesale storefront + two-way quote engine** that locks in **Fina Pay** settlement volume and serves as a natural on-ramp to **Fina POS** adoption—all demonstrably running on lean, self-hosted infrastructure.

---

## 2. Minimal-Cloud Self-Hosted Infrastructure (Single 4 GB RAM Node)

To deliver a rock-solid demo and low-overhead pilot without paying for managed Redis, Sidekiq clusters, or heavy Kubernetes overhead:

* **Compute & Zero-Downtime Deploys:** **Kamal 2** deploys a single Dockerized Rails 8 image behind **Thruster** (or reverse proxy with automatic TLS and health checks).
* *Operational guardrail:* Keep Solid Queue running in its own dedicated worker process/role (do **not** run duplicate inline queue threads inside Puma if a dedicated job worker is already active).


* **Rails 8 "Solid" Stack (Zero Redis Cost):**
* **Solid Queue:** PostgreSQL-backed background jobs for WhatsApp notifications, quote expiration sweeps, payment webhook processing, PDF/XML/QR invoice generation, and Fina POS sync retries.
* **Solid Cache:** PostgreSQL-backed `Rails.cache` for hot catalog reads, storefront theme payloads, and dashboard KPI summaries.
* **Solid Cable:** PostgreSQL/Action Cable adapter powering **Turbo Streams** so merchant dashboards, quote status pills, and the demo WhatsApp console update live without polling or manual page reloads.


* **PostgreSQL 17:** Stores multi-tenant application tables, append-only audit/event logs, and Solid tables, backed up daily via automated `pg_dump` snapshots to S3, Cloudflare R2, or MinIO.
* **Active Storage:** Stores product photos, hero banners (`1920x600` style headers), and generated quote/invoice documents on S3-compatible object storage (`R2`, `S3`, or `MinIO`).

```text
                       ┌───────────────────────────────────────┐
                       │    Kamal Proxy + Thruster (TLS/HTTP)  │
                       └───────────────────┬───────────────────┘
                                           │
             ┌─────────────────────────────┴─────────────────────────────┐
             ▼                                                           ▼
┌─────────────────────────┐                                 ┌─────────────────────────┐
│    Rails 8 Puma Web     │                                 │    Solid Queue Worker   │
│  • Storefront (*.fina.shop│◄─────── PostgreSQL 17 ────────►│  • WhatsApp Cloud API   │
│  • Merchant Admin       │  (App Data + Solid Cache /      │  • Quote Expiry & PDF   │
│  • Buyer Quote Portal   │   Solid Cable / Solid Queue)    │  • Payment & POS Sync  │
│  • Phone OTP Auth       │                                 └───────────┬─────────────┘
└────────────┬────────────┘                                             │
             │                                                           ▼
             ▼                                             ┌─────────────────────────┐
┌─────────────────────────┐                               │ External / Demo Rails   │
│  Object Storage (R2/S3/ │                               │ • Fina Pay / mada / Tabby│
│  MinIO via ActiveStorage│                               │ • WhatsApp Cloud API    │
└─────────────────────────┘                               │ • Fina POS Sync Bridge  │
                                                          └─────────────────────────┘

```

---

## 3. Domain-by-Domain Implementation Specification

### 3.1 Merchant Signup & Onboarding (With AI-Powered Fill-Ins)

* **Frictionless Trial Provisioning:** Merchants sign up with business name, phone/email, and store subdomain (`slug`), immediately creating a `Store` with `subscription_status: "trialing"` (14-day trial) so they can build a catalog, test quotes, and run demos without hitting a paywall before seeing value.
* **3-Step Guided Onboarding Wizard:**
1. **Business & KSA Identity:** Captures Arabic/English store names, **Unified Number 700**, **Commercial Registration (CR) Number**, and 15-digit **Tax Number (VAT)**, plus ZATCA e-invoicing activation status.


2. **AI-Powered Fill-Ins & Smart Catalog Importer:**
* *Multi-Source Extraction:* Accepts pasted supplier URLs, uploaded CSV/Excel exports, or raw text/notes. A background extraction job (`Catalog::AiImportJob`) calls a structured-output LLM prompt to normalize **Arabic + English titles, descriptions, categories, SKU codes, MOQs, and SAR unit prices**.
* *Validation & "Needs Review" Queue:* Unlike a blind import that leaves blank prices or missing categories behind, every imported row is validated (`price > 0` when `show_price` is enabled, valid SKU, category mapping). Incomplete or low-confidence fields land in a **Needs Review** drawer with one-click AI fill-in suggestions or inline edits before publishing.


* *AI Copy & Volume Tier Suggestions:* Given a product title + base price, generates bilingual descriptions (`ar` & `en`), category tags, and suggested wholesale quantity tiers (e.g., `1–4`, `5–14`, `15+` units).


3. **Payments & Channel Defaults:** Enables **Fina Pay** by default, configures optional wholesale/KSA payment methods, and links WhatsApp alerts.



### 3.2 Main Dashboard

* **Wholesale Command Center:** Replaces passive counters with actionable queues:
* **Top KPI Strip:** `Total Products` (active vs. draft/needs-review), `Open Quote Requests` (broken down by `Needs Merchant Reply` vs. `Awaiting Buyer`), `Accepted Quotes Value (SAR)`, `Pending Payments`, and `Monthly Views / Conversion Rate`.


* **Priority Action Panel:** Lists unquoted RFQs, buyer counter-offers/revisions, and quotes nearing `expires_at`.
* **Real-Time Activity Feed (Turbo Streams):** Streams incoming quote requests, buyer acceptances/rejections, WhatsApp inbound messages, and paid orders live.
* **Compliance & Ecosystem Strip:** Shows live status pills for **Fina Pay**, **ZATCA E-Invoicing**, and **Fina POS Sync** with direct links to resolve any inactive setup.





### 3.3 Analytics

* **Wholesale Funnel & Operational Metrics:**
* Tracks `Page Views`, `Visitors`, `Product Views`, `Quote Requests`, `Quote-to-Acceptance Rate`, `Quote-to-Paid Conversion`, `Average Quote Value (SAR)`, and `Median Quote Response Time`.


* **Fast, Cache-Backed Queries:** Uses indexed PostgreSQL aggregates grouped by day/category/product and cached via **Solid Cache** with automatic cache-key invalidation on quote/order/visit events.

### 3.4 Quotes (End-to-End RFQ, Pricing, Negotiation & Accept/Reject)

Wholesale buyers negotiate bulk quantities and terms rather than clicking a single retail buy button. Model quotes around a strict state machine (`Quotes::TransitionService`) inside `ActiveRecord::Base.transaction` with row-level locking (`lock!`):

* **States:** `submitted` -> `viewed` -> `quoted` -> `revised` -> `accepted` | `rejected` | `expired` | `converted_to_order`.
* **Step-by-Step Workflow:**
1. **Buyer Submits RFQ:** Adds products and requested quantities (enforcing `min_order_qty` / MOQ and calculating automatic volume-tier unit prices via `Wholesale::QuotePricingCalculator`), adds buyer notes/delivery preferences, and submits a `QuoteRequest` (`submitted`) with an immutable snapshot on `QuoteItem` (`sku_snapshot`, `title_snapshot`, `requested_qty`, `requested_unit_price_halalas`).
2. **Merchant Replies with Quote:** Merchant opens the RFQ (transitioning `submitted` -> `viewed` and logging a `QuoteEvent`), adjusts `quoted_qty` and `quoted_unit_price_halalas` per line item, adds shipping/freight (`shipping_halalas`) or bulk discounts (`discount_halalas`), sets `expires_at`, and sends (`quoted`).
3. **Buyer Accepts or Rejects:** Buyer opens a unique tokenized quote link (`/quotes/:token`) or phone-authenticated buyer portal:
* **Accept:** Atomically verifies status (`quoted` or `revised`) and non-expiration, sets status to `accepted`, creates an `Order` (`pending_payment`) with exact SAR + 15% VAT math, initiates **Fina Pay** checkout options, logs a `QuoteEvent`, and broadcasts via **Turbo Streams**.
* **Reject:** Sets status to `rejected`, records `rejection_reason` and `responded_at`, logs a `QuoteEvent`, and notifies the merchant.
* **Revision Loop:** Allows buyers to request adjustments (`revised`) and merchants to issue updated offers with full `QuoteEvent` history.





### 3.5 Subscriptions (Merchant SaaS Billing & FinaX Incentives)

* **Subscription Lifecycle (`StoreSubscription`):** Tracks `trialing` (14-day free trial), `active`, `past_due`, and `canceled` states (`Start Free Trial` / plan management) backed by a `Billing::ProviderAdapter` (supporting Stripe Billing and/or local/Fina billing providers) with idempotent webhook handling.


* **Smart Gating for FinaX:** Merchants can create a storefront and send quotes immediately during trial; higher catalog/SKU limits, custom domains, multi-user roles, or automated **Fina POS** sync map to paid plans—or unlock via **Fina Pay** volume and POS adoption incentives.

### 3.6 Payment Methods (Multi-Rail Architecture: Fina Pay, mada, Tabby, Apple Pay, STC Pay & More)

Route all payment rails through a unified `PaymentTransaction` ledger (`initiated -> requires_action -> authorized -> captured | paid | failed | refunded | canceled`) and `Payments::GatewayRouter` so merchants and buyers get a consistent experience without controller bloat:

* **Fina Pay (Always Available):** Pre-enabled on every payable order/quote as the primary FinaX rail, supporting KSA payment flows (such as **mada**, **Apple Pay**, cards, and Fina Pay / trade financing flows) and feeding GMV signals back to Fina.
* **`mada` (Saudi Debit Network):** Integrated via a SAMA-licensed KSA gateway (e.g., Moyasar / Tap / PayTabs) with 3-D Secure (`3DS`) flow and mandatory server-side verification (`status == "paid"`, exact `amount_halalas`, `currency == "SAR"`).
* **Tabby (Split Installments / BNPL):** Creates a KSA checkout session (`/api/v2/checkout` on `api.tabby.sa` with order items, buyer details, and `success` / `cancel` / `failure` URLs), handles buyer redirect + webhook authorization, supports **Capture** upon fulfillment/shipment and **Refunds/Cancellations**, and respects Tabby's eligibility/checkout rules.
* **Apple Pay & STC Pay:** Surfaced through supported KSA payment rails (with HTTPS + Apple Pay domain association file for Apple Pay, and wallet intent/OTP verification for STC Pay).
* **Wholesale / Offline Rails:** Supports **Bank Transfer** (with IBAN + transfer receipt upload), **Cash on Delivery (COD)**, and **Approved Credit / Net Terms** for vetted wholesale accounts.
* **Demo Simulator Mode:** When live merchant/gateway API keys aren't configured during a demo, `Payments::DemoAdapter` lets you simulate `mada` 3DS success, `Tabby` approval, `Fina Pay` settlement, or a declined card + retry in one click.

### 3.7 WhatsApp & Other Communication Channels

* **Working WhatsApp Channel (WhatsApp Cloud API):**
* Integrates directly with Meta's **WhatsApp Cloud API** (`graph.facebook.com`), implementing `GET` webhook handshake verification and `POST` `X-Hub-Signature-256` HMAC signature verification.
* Processes outbound sends and inbound events asynchronously via **Solid Queue**, deduplicating by `wa_message_id` (`wamid...`) in `whatsapp_messages`.
* Handles **WhatsApp's 24-hour customer service window** cleanly: uses approved message templates for proactive notifications outside a 24-hour window, and sends rich interactive/free-form messages once a buyer engages within the 24-hour window.
* **Two-Way Quote Actions Over WhatsApp:** Sends quote notifications with **Interactive Reply Buttons** (`Accept Quote`, `Reject Quote`, `Request Revision`). Tapping a button or replying on WhatsApp triggers `Quotes::TransitionService` and updates the merchant dashboard live via **Turbo Streams**.
* **Live Demo WhatsApp Simulator:** Includes an in-app **WhatsApp Phone Simulator** panel for your presentation so you can send quotes, view formatted WhatsApp messages, and click simulated buyer replies (`Accept Quote` / `Reject Quote`) reliably on stage.


* **Other Channels:** Transactional **Email** (quote summaries/PDFs, order receipts) and **SMS / WhatsApp OTP** for buyer phone login.

### 3.8 Merchant Themes & Website Customization

* **Bilingual (`ar` RTL / `en` LTR) Wholesale Themes:** Ships 2–3 responsive templates tuned for wholesale catalogs (clear SKU tables, MOQ badges, tier price tables, and fast "Add to Quote" actions) with automatic `dir="rtl"` for Arabic and `dir="ltr"` for English.
* **Live Theme Customizer:** Supports template selection, color palette, logo upload, **Hero Banner** customization (banner style, `1920x600` banner image, Arabic/English title & subtitle), featured product selection, and store-wide `Show Prices` default behavior.



### 3.9 Shops (Multi-Tenant Storefronts, Subdomains & Wholesale UX)

* **Subdomain & Custom Domain Routing:** Resolves `Current.store` from `request.host` (`{slug}.fina.shop` or mapped custom domain) with strict per-tenant isolation (`store_id` scoping + PostgreSQL Row-Level Security policies).
* **Wholesale Buyer Ergonomics:**
* **Bulk Quick-Order Grid:** Filter/search SKUs by name or SKU code and enter quantities across multiple items in one view.
* **One-Click Reorder:** Clone past accepted quotes or paid orders into a new quote request or order with current tier pricing.



### 3.10 Customer Signup (Phone-Only Authentication)

* **Phone-Only Sign-In & Sign-Up:** Buyers authenticate **only via mobile phone number** (normalized to E.164, optimized for Saudi `+966` numbers) and a **6-digit OTP**—no passwords or required email addresses.
* **Frictionless Buyer Profile:** Stores buyer phone, optional name, company name, VAT/tax ID, and delivery address per store so repeat wholesale buyers submit RFQs in seconds.

### 3.11 Customer Payments

* **Quote-to-Checkout Flow:** Accepting a quote generates an itemized SAR invoice (`subtotal`, `tier discount`, `shipping/freight`, `15% VAT`, `total`) and routes the buyer to **Fina Pay** (or their chosen rail: `mada`, `Apple Pay`, `STC Pay`, `Tabby`, or approved wholesale payment method).
* **ZATCA Phase 1 QR & Receipts:** Paid orders generate a **ZATCA Base64 TLV QR code** (Seller Name, 15-digit VAT Number, ISO-8601 timestamp, Total with VAT, VAT Amount) on the invoice/receipt and dispatch confirmation via WhatsApp and email.

### 3.12 Updating Inventory (With and Without Fina POS)

Model inventory from Day 1 with **location/channel awareness** (`inventory_locations` + `inventory_levels`) so **Fina POS** integration is an additive sync layer rather than a rewrite:

* **Without Fina POS (Web Store Managed):**
* Merchants update stock quantities and `min_order_qty` (MOQ) directly in the dashboard, bulk editor, or CSV import.
* Order placement and payment settlement adjust stock inside a database transaction with pessimistic row locks (`lock!`) to prevent overselling under concurrent requests.


* **With Fina POS Connected:**
* Maps SKUs (`external_pos_sku`) and branches/terminals (`POS_STORE` vs. `ONLINE`) to **Fina POS**.
* Publishes `inventory.adjusted` and `order.paid` domain events asynchronously via **Solid Queue** (`PosSync::EventPublisher`) with exponential retry backoff and dead-letter inspection.
* Includes a **Fina POS Sync Simulator** in your demo so you can show live stock/order synchronization between **Fina Shops** and **Fina POS** during your pitch.



### 3.13 Landing Page Improvements

* **Dual-Track Value Proposition:** Clearly addresses both **wholesale merchants** (fast bilingual storefront, tiered pricing, quote negotiation, WhatsApp alerts, Fina Pay) and **FinaX leadership** (how Fina Shops acts as a low-friction acquisition funnel into **Fina Pay** and **Fina POS**).
* **Instant Demo Access:** Provides one-click entry into a pre-seeded wholesale demo store (`elshohail.fina.shop` style with commercial mixers, ovens, active quotes, WhatsApp simulator, and payment/POS simulators).

---

## 4. Core Rails 8 Schema & Key Service Contracts

### 4.1 Essential Schema Additions (`db/schema.rb` Blueprint)

```ruby
create_table :stores do |t|
  t.string :name_ar, null: false
  t.string :name_en
  t.string :subdomain, null: false, index: { unique: true }
  t.string :custom_domain, index: { unique: true }
  t.string :unified_number_700
  t.string :cr_number
  t.string :vat_number
  t.boolean :zatca_enabled, default: false, null: false
  t.boolean :show_prices_default, default: true, null: false
  t.boolean :pos_sync_enabled, default: false, null: false
  t.string :fina_merchant_id
  t.string :subscription_status, default: "trialing", null: false
  t.datetime :trial_ends_at
  t.jsonb :theme_config, default: {}, null: false
  t.timestamps
end

create_table :price_tiers do |t|
  t.references :product, null: false, foreign_key: true
  t.integer :min_quantity, null: false
  t.bigint :unit_price_halalas, null: false
  t.timestamps
end
add_index :price_tiers, [:product_id, :min_quantity], unique: true

create_table :phone_otps do |t|
  t.references :store, null: false, foreign_key: true
  t.string :phone_e164, null: false
  t.string :code_digest, null: false
  t.datetime :expires_at, null: false
  t.integer :attempts, default: 0, null: false
  t.datetime :verified_at
  t.timestamps
end
add_index :phone_otps, [:store_id, :phone_e164]

create_table :quote_requests do |t|
  t.references :store, null: false, foreign_key: true
  t.references :customer, null: false, foreign_key: true
  t.string :reference_code, null: false
  t.string :status, default: "submitted", null: false
  t.text :buyer_notes
  t.text :merchant_notes
  t.text :rejection_reason
  t.bigint :subtotal_halalas, default: 0, null: false
  t.bigint :discount_halalas, default: 0, null: false
  t.bigint :shipping_halalas, default: 0, null: false
  t.bigint :vat_halalas, default: 0, null: false
  t.bigint :total_halalas, default: 0, null: false
  t.datetime :quoted_at
  t.datetime :expires_at
  t.datetime :responded_at
  t.timestamps
end
add_index :quote_requests, [:store_id, :reference_code], unique: true

create_table :quote_items do |t|
  t.references :quote_request, null: false, foreign_key: true
  t.references :product, null: false, foreign_key: true
  t.string :sku_snapshot, null: false
  t.string :title_snapshot, null: false
  t.integer :requested_qty, null: false
  t.integer :quoted_qty, null: false
  t.bigint :requested_unit_price_halalas, null: false
  t.bigint :quoted_unit_price_halalas, null: false
  t.bigint :line_total_halalas, null: false
  t.timestamps
end

create_table :quote_events do |t|
  t.references :quote_request, null: false, foreign_key: true
  t.string :actor_type, null: false # buyer, merchant, system, whatsapp
  t.string :action, null: false
  t.text :note
  t.jsonb :metadata, default: {}, null: false
  t.timestamps
end

create_table :payment_transactions do |t|
  t.references :store, null: false, foreign_key: true
  t.references :order, null: false, foreign_key: true
  t.string :provider, null: false       # fina_pay, moyasar, tabby, demo
  t.string :method_type, null: false    # fina_pay, mada, apple_pay, stc_pay, tabby, bank_transfer, cod
  t.string :external_id, null: false
  t.string :status, default: "initiated", null: false
  t.bigint :amount_halalas, null: false
  t.string :currency, default: "SAR", null: false
  t.string :checkout_url
  t.string :idempotency_key, null: false
  t.jsonb :metadata, default: {}, null: false
  t.jsonb :raw_response, default: {}, null: false
  t.datetime :paid_at
  t.timestamps
end
add_index :payment_transactions, [:provider, :external_id], unique: true
add_index :payment_transactions, :idempotency_key, unique: true

create_table :whatsapp_messages do |t|
  t.references :store, null: false, foreign_key: true
  t.references :quote_request, foreign_key: true
  t.string :wa_message_id, index: { unique: true }
  t.string :direction, null: false # outbound, inbound
  t.string :recipient_phone
  t.string :sender_wa_id
  t.string :delivery_status, default: "queued", null: false
  t.string :message_kind, default: "text", null: false
  t.text :body
  t.jsonb :raw_payload, default: {}, null: false
  t.timestamps
end

create_table :webhook_events do |t|
  t.string :provider, null: false
  t.string :event_id, null: false
  t.string :event_type, null: false
  t.jsonb :payload, default: {}, null: false
  t.datetime :processed_at
  t.timestamps
end
add_index :webhook_events, [:provider, :event_id], unique: true

```

### 4.2 Core Service Classes to Build

* `Wholesale::QuotePricingCalculator` — Resolves volume `PriceTier` unit pricing, MOQs, discounts, shipping, and 15% SAR VAT (`((taxable_halalas * 15) + 50) / 100`).
* `Quotes::TransitionService` — Executes locked quote state transitions (`submitted -> viewed -> quoted -> revised -> accepted / rejected`), creates `Order` on acceptance, logs `QuoteEvent`, enqueues WhatsApp/email jobs, and broadcasts Turbo Streams.
* `Catalog::AiImportJob` — Extracts structured bilingual catalog rows from URLs/CSVs/text and flags missing fields for review.
* `Auth::PhoneOtpService` — Generates hashed 6-digit OTPs, enforces rate limits/attempt caps, and signs in phone-only wholesale buyers.
* `Payments::GatewayRouter` & `Payments::SettleOrderService` — Routes `Fina Pay`, `mada`, `Apple Pay`, `STC Pay`, `Tabby`, and `DemoAdapter` transactions and settles orders idempotently.
* `Whatsapp::CloudApiClient`, `Whatsapp::WebhookProcessorJob` & `Whatsapp::DemoConsole` — Handles Meta WhatsApp Cloud API webhooks/buttons/24h window logic plus a live demo simulator.
* `PosSync::EventPublisher` & `Zatca::QrEncoder` — Syncs stock/orders with Fina POS (and demo POS simulator) and generates ZATCA TLV QR codes.

---

## 5. Contract Pitch & Demo Execution Plan

* **What You Bring to FinaX:** A working, self-hosted Rails 8 demo on a single minimal VM showing **wholesale tiered quotes**, **phone-only buyer login**, **live WhatsApp quote accept/reject**, **multi-rail payments (`Fina Pay`, `mada`, `Tabby`, etc.)**, **AI-assisted catalog fill-ins**, and **Fina POS-ready inventory sync**.
* **Suggested Contract Framing:** Propose a crisp, time-boxed engagement (e.g., **Phase 1: Core Wholesale RFQ + WhatsApp + Multi-Rail Payments & POS Bridge Module**, followed by **Phase 2: Production Hardening, ZATCA/POS Integration & Rollout**) where FinaX gets working code they can inspect, test, and adopt immediately.

If you'd like, I can now generate **ready-to-run Rails 8 code** (migrations, models, `Quotes::TransitionService`, `Payments::SettleOrderService`, or the WhatsApp webhook + simulator) or draft a **one-page contract/pitch brief** to pair with your deck.