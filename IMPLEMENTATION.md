# Fina Shops — Step-by-Step Implementation Plan

## Context
`PLAN.md` is a design doc for **Fina Shops**: a multi-tenant, bilingual (ar/en) Rails 8 wholesale storefront + RFQ/quote engine with WhatsApp, multi-rail payments (Fina Pay/mada/Tabby…), ZATCA QR, and Fina POS sync, deployed on one VM with Kamal 2. The repo is empty (only `PLAN.md`). Goal: a series of small, individually testable steps, ordered **demo-first** — the pitch flow (storefront → RFQ → merchant quote → WhatsApp simulator accept → demo payment → ZATCA QR receipt) works end-to-end by Milestone 6, then real integrations and production hardening follow.

**Choices:** Rails 8 · PostgreSQL 17 · Minitest + fixtures + Capybara system tests · Tailwind (logical `ms-/me-/ps-/pe-` utilities for RTL) · Hotwire · Solid Queue/Cache/Cable · Kamal 2.

**Gaps filled vs PLAN.md §4.1** (doc omits them): `users` (merchant staff), `categories`, `products`, `customers`, `orders`, `order_items`, `store_subscriptions`, `catalog_imports`.

**Deliberate deviation from PLAN.md §3.12:** each shop has **one location** and a **single stock count per product** (`products.stock_qty`). Multi-location inventory (`inventory_locations` / `inventory_levels`, ONLINE vs POS_STORE) is deferred; all stock changes go through `Inventory::AdjustService` so adding locations later is contained to that service and its callers.

**Conventions for every step**
- Each step = one PR-sized change ending with green `bin/rails test` (+ `test:system` when UI) and `bin/rubocop`.
- Money: `bigint *_halalas` only; a `Money`-free `Halalas` formatting helper. Never floats.
- All tenant models `belongs_to :store`, queried via `Current.store` scopes.
- Status fields: string columns + Rails `enum ... validate: true`.
- Copy: reuse FinaShop wording from `docs/copy/fina_shop.{ar,en}.json` (extracted from fina.shop) for any user-facing string; brand is "FinaShop".

---

## Milestone 0 — Foundation
1. ✅ **App skeleton.** `rails new fina_shop -d postgresql --css tailwind` (Rails 8, Solid trio, Kamal, Thruster included). Add `bin/dev`, CI script `bin/ci` (rubocop, brakeman, tests). *Test:* `bin/rails test` passes; `GET /up` returns 200.
2. ✅ **i18n + RTL base.** `config.i18n.available_locales = [:ar, :en]`, default `:ar`; locale from `?locale`/cookie/`Accept-Language`; layout sets `<html lang dir>`. Locale files `config/locales/{ar,en}.yml`; `i18n-tasks` gem to catch missing keys. *Test:* controller test asserts `dir="rtl"` for ar, `ltr` for en; `i18n-tasks missing` is empty.
3. ✅ **Money helpers.** `app/lib/halalas.rb` (`format(halalas, locale)` → `1,234.50 ر.س` / `SAR 1,234.50`, `from_sar(string)`), and `Vat.amount(taxable) = ((taxable * 15) + 50) / 100`. *Test:* unit tests incl. rounding edges (1, 49, 50, 333 halalas).

## Milestone 1 — Tenancy & Merchant Auth
4. ✅ **Store model.** Migration per §4.1 `stores` plus FinaShop store-settings fields: `description_ar/en`, contact (`email`, `phone`, `whatsapp_phone` as E.164 via `phonelib`, `website`), Saudi national address (`country_code` default SA, `region`, `city`, `district`, `street`, `building_number`, `postal_code`), `show_stock_default`. Subdomain validation: lowercase, reserved words (`www admin app api` …). KSA ID formats (VAT 15 digits starting/ending 3, CR 10 digits, 700 number). `national_address_complete?` gates ZATCA. *Test:* model validations, normalization, uniqueness.
5. **Tenant resolution.** `Current` (`store`, `user`, `customer`); `StoreResolver` concern resolves from `request.host` (`{slug}.fina.shop` or `custom_domain`, dev uses `{slug}.lvh.me`). Route constraints: apex → marketing/signup, subdomain → storefront + `/admin`. 404 for unknown store. *Test:* integration tests for subdomain, custom domain, unknown host.
6. **Merchant auth.** `bin/rails generate authentication` (Rails 8) → `users`, `sessions`; add `store_id` + `role` (owner/staff) to users; admin base controller requires user of `Current.store`. *Test:* user of store A cannot access store B admin (403/redirect).
7. **Merchant signup + trial.** Apex `/signup`: business name, email/phone, password, slug → creates `Store` (`subscription_status: trialing`, `trial_ends_at: 14.days.from_now`) + owner user, redirects to `{slug}` admin. *Test:* system test signup → lands on admin dashboard; duplicate slug errors.
8. **Admin shell.** Bilingual sidebar layout (Dashboard, Products, Categories, Quotes, Customers, Analytics, Theme, Settings, Billing) with empty pages + locale switcher. *Test:* system test navigates every nav link in both locales.

## Milestone 2 — Catalog & Inventory
9. **Categories CRUD.** `categories` (store, name_ar, name_en, position, parent_id). *Test:* CRUD + tenant scoping tests.
10. **Products CRUD.** `products` (store, category, sku unique per store, title_ar/en, description_ar/en, `base_price_halalas`, `min_order_qty` default 1, `show_price` nullable → falls back to store default, `status` draft/needs_review/active, `external_pos_sku`), Active Storage `images` (local disk in dev). Validation: `active` requires price > 0 when price shown, sku, category. *Test:* model validations (the "missing price" bug from §1 can't publish); controller CRUD.
11. **Price tiers.** `price_tiers` per §4.1, nested form on product (e.g. 1–4, 5–14, 15+). *Test:* unique `min_quantity`; tier price ≤ base.
12. **`Wholesale::QuotePricingCalculator`.** Input: lines `{product, qty}` + discount + shipping → per-line tier unit price, MOQ errors, subtotal, VAT, total. *Test:* pure unit tests for tier boundaries, MOQ violation, VAT rounding, discount > subtotal guard.
13. **Stock count.** Add `products.stock_qty` (integer, default 0, `>= 0` check constraint). `Inventory::AdjustService` (product, delta, reason) with `lock!` is the only writer of `stock_qty`. *Test:* concurrent decrement test (threads) never goes negative; insufficient stock raises.
14. **Bulk stock/MOQ editor.** Admin grid editing `stock_qty` + MOQ via Turbo Frames, writes through `Inventory::AdjustService`. *Test:* system test edits 3 rows.

## Milestone 3 — Storefront & Buyer Auth
15. **Storefront theme v1.** Public catalog: category list, product grid, product page with SKU, MOQ badge, tier table; prices hidden per `show_price`. Bilingual, RTL. *Test:* system tests both locales; hidden prices not in HTML.
16. **Quick-order grid + quote cart.** Search by name/SKU, qty inputs across items, "Add to Quote" (session-backed cart, Stimulus live tier price). *Test:* system test adds 3 SKUs; MOQ errors shown.
17. **Customers + phone normalization.** `customers` (store, phone_e164 unique per store, name, company, vat_number, address jsonb). `phonelib` normalization defaulting to `SA`. *Test:* `0501234567`, `+966 50…`, `00966…` → same E.164.
18. **`Auth::PhoneOtpService` + OTP delivery stub.** `phone_otps` per §4.1; 6-digit code, `BCrypt` digest, 5-min expiry, 5 attempts, rate-limit via Rails 8 `rate_limit`; delivery through `Otp::Deliverer` interface with `LogDeliverer` (dev shows code in flash/console). Signed `customer_session` cookie. *Test:* expiry, attempt cap, wrong code, success creates customer.

## Milestone 4 — Quotes (core demo)
19. **Quote schema.** `quote_requests`, `quote_items`, `quote_events` per §4.1, plus `quote_requests.public_token` (has_secure_token) and reference code generator (`Q-2026-000123` per store). *Test:* model tests.
20. **Buyer submits RFQ.** Cart → `Quotes::SubmitService` snapshots sku/title/requested price via calculator, logs `QuoteEvent(submitted)`. *Test:* service test snapshots survive later product price edits.
21. **`Quotes::TransitionService`.** Allowed-transition table, `transaction` + `lock!`, logs event, raises `InvalidTransition`; expiry check for accept. No side effects yet besides events. *Test:* full transition matrix test; stale/expired accept rejected.
22. **Merchant quote inbox + reply.** Admin list filtered by status (Needs reply / Awaiting buyer); opening marks `viewed`; editor for `quoted_qty`, `quoted_unit_price_halalas`, shipping, discount, `expires_at`, notes → `quoted` with recalculated totals. *Test:* system test merchant quotes an RFQ.
23. **Buyer quote page `/quotes/:token`.** Shows itemized SAR totals + VAT; Accept / Reject (reason) / Request revision. *Test:* system test each action; revised → merchant re-quotes.
24. **Orders on accept.** `orders` (store, customer, quote_request, number, status pending_payment/paid/fulfilled/canceled, subtotal/discount/shipping/vat/total halalas) + `order_items`. Accept transition creates order inside same transaction. *Test:* totals equal quote totals; double-accept creates one order.
25. **Live updates.** Turbo Stream broadcasts from TransitionService (`after_commit`) to `[store, :quotes]` stream; admin inbox/status pills update live (Solid Cable). *Test:* system test with two sessions — buyer accepts, merchant page updates without reload.
26. **Expiry sweep.** `Quotes::ExpireJob` recurring via `config/recurring.yml` (Solid Queue). *Test:* job test expires past-due quoted quotes only.

## Milestone 5 — WhatsApp (simulator first)
27. **`whatsapp_messages` + channel abstraction.** `Whatsapp::Channel` interface; `Whatsapp::DemoAdapter` stores outbound messages locally. `Whatsapp::NotifyJob` enqueued on quote `quoted` with interactive buttons payload (Accept/Reject/Request Revision, button ids embed quote token). *Test:* job test creates outbound message with 3 buttons.
28. **Demo WhatsApp simulator panel.** Admin `/admin/demo/whatsapp`: phone-styled thread (Turbo Stream), clickable buttons post simulated inbound payload through the **same** `Whatsapp::InboundProcessor` used by real webhooks → TransitionService. *Test:* system test click "Accept Quote" → quote accepted, dashboard updates.

## Milestone 6 — Payments (demo) & ZATCA → **end-to-end demo complete**
29. **`payment_transactions` + `Payments::GatewayRouter`.** Schema per §4.1; adapter interface (`create_checkout`, `verify`, `capture`, `refund`); `Payments::DemoAdapter` (simulate mada 3DS success, Tabby approval, Fina Pay settlement, decline). *Test:* router picks demo adapter when no keys configured.
30. **`Payments::SettleOrderService`.** Idempotent (idempotency_key, `lock!`), verifies amount/currency, marks order paid, decrements each product's `stock_qty` via `Inventory::AdjustService`, logs event. *Test:* duplicate settle is a no-op; amount mismatch fails.
31. **Buyer checkout page.** From order: choose rail (Fina Pay default, mada, Apple Pay, STC Pay, Tabby, bank transfer, COD) → demo simulator screen → success/failure + retry. *Test:* system test pay via each demo outcome.
32. **`Zatca::QrEncoder` + receipt.** TLV tags 1–5 Base64, rendered via `rqrcode` SVG on invoice/receipt page and PDF (`prawn`). *Test:* encoder test against a known ZATCA sample vector; decode round-trip.
33. **Demo seed + landing page.** `db/seeds/demo.rb` builds `elshohail` store (mixers, ovens, tiers, quotes in every state, customers). Apex landing page (dual-track merchants/FinaX) with "Open demo store" one-click login. *Test:* `bin/rails db:seed` idempotent; system test for the full pitch script: landing → demo → RFQ → quote → WhatsApp accept → pay → QR receipt.

## Milestone 7 — Dashboard & Analytics
34. **Dashboard KPIs + priority panel.** KPI strip, unquoted RFQs, revision requests, expiring quotes, compliance pills (Fina Pay/ZATCA/POS), live activity feed. Cached via Solid Cache keyed on store `updated_at`-style counters. *Test:* KPI query tests with fixtures; cache invalidates on new quote.
35. **Visit tracking.** Lightweight `page_visits` (store, path, product_id, visitor_hash, day) written by async job. *Test:* job test; bots ignored.
36. **Analytics page.** Funnel, quote→accept, quote→paid, avg quote value, median response time, by day/category. *Test:* query object unit tests with known fixtures.

## Milestone 8 — Onboarding & AI Import
37. **Onboarding wizard (3 steps).** KSA identity (700 number, CR, 15-digit VAT validation starting/ending with 3), import step, payments/channel defaults. Dashboard banner until complete. *Test:* VAT validator tests; system test wizard.
38. **CSV/Excel import (no AI).** `catalog_imports` + rows; `roo` parse → rows validated → Needs Review drawer → publish. *Test:* fixture CSV with missing price lands in Needs Review.
39. **`Catalog::AiImportJob`.** Claude API (`anthropic` gem, model `claude-sonnet-5-5`, structured JSON output) for URL/text/CSV normalization into same row format; confidence flags → Needs Review. Behind an adapter so tests use a stub. *Test:* job test with stubbed client response.
40. **AI copy & tier suggestions.** Button on product form → bilingual description + tier suggestion (Turbo Frame). *Test:* stubbed service test.

## Milestone 9 — Themes & Shops UX
41. **Theme config + customizer.** `theme_config` jsonb schema (template, colors, logo, hero banner ar/en, featured products); live preview iframe. *Test:* config validation; system test change color → preview updates.
42. **2 more templates.** Partials switched by `theme_config.template`. *Test:* render test per template.
43. **Reorder.** Clone accepted quote / paid order into new cart at current tier pricing. *Test:* service test.
44. **Custom domains.** Admin field + DNS instructions; resolver already supports it. *Test:* integration test.
45. **Postgres RLS.** Policies on tenant tables using `SET app.current_store_id` per request (around_action), app user non-superuser. *Test:* raw SQL cross-tenant read returns nothing.

## Milestone 10 — Real Integrations
46. **WhatsApp Cloud API.** `Whatsapp::CloudApiClient` (send text/template/interactive), webhook `GET` verify + `POST` `X-Hub-Signature-256` HMAC, `webhook_events` dedupe, `WebhookProcessorJob`, `wa_message_id` dedupe, 24h window → template vs free-form. *Test:* signature tests, webhook fixture payloads, WebMock for Graph API.
47. **Real OTP delivery.** WhatsApp auth template + SMS fallback (Unifonic/Twilio adapter). *Test:* WebMock.
48. **Email.** Action Mailer quote summary (PDF attached), order receipt. *Test:* mailer tests.
49. **mada / Apple Pay / STC Pay via Moyasar adapter.** Checkout + 3DS redirect + server-side verify (`paid`, exact amount, SAR) + webhook. Apple Pay domain association file route. *Test:* WebMock + webhook fixtures.
50. **Tabby adapter.** Checkout session, webhook authorization, capture on fulfillment, refund/cancel. *Test:* WebMock.
51. **Fina Pay adapter.** Against Fina's API (or contract-stub until spec available). *Test:* WebMock.
52. **Offline rails.** Bank transfer (IBAN + receipt upload, merchant confirms), COD, net terms for approved customers. *Test:* system tests.
53. **Fina POS sync.** `PosSync::EventPublisher` (`inventory.adjusted`, `order.paid`) via Solid Queue with exponential backoff + dead-letter table and admin retry; inbound stock webhook sets the product's single `stock_qty` (SKU mapped via `external_pos_sku`); **POS Sync Simulator** demo panel. *(If POS branches need separate stock, introduce multi-location inventory here.)* *Test:* retry/backoff job tests; simulator system test.

## Milestone 11 — Subscriptions
54. **`store_subscriptions` + `Billing::ProviderAdapter`.** Stripe Billing adapter + idempotent webhooks; trial→active/past_due/canceled; billing page. *Test:* webhook state-machine tests.
55. **Plan gating.** `Plan` limits (SKU count, custom domain, staff users, POS sync) enforced via policy object; trial-expiry banner. *Test:* limit enforcement tests.

## Milestone 12 — Production & Deploy
56. **Storage + config.** Active Storage S3-compatible service (R2/MinIO), credentials per env. *Test:* boot in production mode locally with MinIO in docker.
57. **Kamal 2 deploy.** `config/deploy.yml` with `web` + dedicated `job` role (`SOLID_QUEUE_IN_PUMA` off), Postgres 17 accessory, wildcard TLS for `*.fina.shop` (DNS challenge). *Test:* `kamal deploy` to staging VM; `/up` healthy; demo script runs.
58. **Backups + monitoring.** Daily `pg_dump` → R2 via recurring job/cron accessory; restore drill doc; error tracking. *Test:* restore a backup to a scratch DB.
59. **Hardening pass.** Brakeman clean, rate limits on OTP/webhooks, CSP, audit of tenant scoping, load test (k6) catalog + quote endpoints on 4 GB VM.

---

## Verification (overall)
- Every step: `bin/ci` green (rubocop, brakeman, `bin/rails test`, `bin/rails test:system`).
- After step 33: run `bin/rails db:seed` then `bin/dev`, open `http://lvh.me:3000` → "Open demo store" and walk the pitch script manually in both ar and en (RTL layout check), with the WhatsApp simulator and payment simulator in a second window to confirm live Turbo updates.
- After step 57: repeat the pitch script against the staging VM.
