# ADR-004: Payment Provider Choice

**Status:** APPROVED — Gate 0 signed off 2026-03-07
**Date:** 2026-03-08
**Author:** Orchestrator
**Linear:** PYR-25
**Deciders:** Human owner (cost decision — GATE required)

---

## Context

Phase 2 introduces a £5 fixed-stake paid matchmaking league. The platform needs to:
1. Accept payments (top-ups) from users via card or Apple Pay
2. Pay out winnings (withdrawals) to users' bank accounts
3. Potentially support KYC/age verification (if Stripe Identity is chosen for compliance)

The provider must support GBP, UK banking, Apple Pay, and ideally instant payouts for withdrawals.

---

## Options Evaluated

### Option 1: Stripe ⭐ Recommended

**Pros**
- Industry standard — best-in-class iOS SDK (`Stripe iOS SDK`) with prebuilt `PaymentSheet`
- Apple Pay support out of the box
- Stripe Connect for payouts to users' bank accounts (instant payout available)
- Stripe Identity available as KYC/age verification layer (removes need for separate provider)
- Excellent documentation; well-understood by iOS and backend engineers
- Webhooks reliable and well-tested at scale

**Cons**
- Cost: 1.5% + 20p per UK card transaction (Stripe pricing for UK businesses, as of 2026)
- Additional 0.5% for European cards
- Instant payouts: additional 1% fee per instant payout
- Stripe Identity: £1.50–£2.50 per verified user (if used for KYC)

**Integration**
- iOS: `StripePaymentSheet` for top-up; no card data touches our servers
- Backend: Edge Function validates `PaymentIntent` ID against Stripe API before crediting wallet
- Payouts: `Transfer` to connected `ExternalAccount` (user's bank account)

---

### Option 2: Checkout.com

**Pros**
- Competitive pricing for high-volume UK merchants (negotiable rates)
- Strong fraud tooling
- Apple Pay supported

**Cons**
- SDK less mature than Stripe; more integration work
- Payout/disbursement product less developed than Stripe Connect
- Smaller developer community; less documentation
- No built-in KYC product — separate vendor needed

**Verdict:** Viable at scale, but higher integration cost now with no offsetting advantage at our volume.

---

### Option 3: PaySafe

**Pros**
- Strong in gambling/gaming sector — regulatory familiarity
- Supports GBP

**Cons**
- Primarily B2C wallet product — not a good fit for our iOS card-payment-to-wallet flow
- SDK dated; poor iOS developer experience
- Payout product not suitable for direct bank transfers at our scale
- Higher per-transaction cost than Stripe at low volumes

**Verdict:** Not recommended — wrong product category for our use case.

---

## Recommendation

**Stripe** — for the following reasons:

1. **Fastest path to integration** — `PaymentSheet` and `Stripe iOS SDK` are best-in-class; no custom card UI needed
2. **Single provider for payments + payouts** — Stripe Connect eliminates need for a separate disbursement vendor
3. **KYC optionality** — Stripe Identity can cover age verification if chosen for compliance (GATE PYR-26), avoiding a second vendor
4. **Cost is proportional** — at £5 stake with ~1.5% + 20p fee per top-up, platform absorbs ~27p per user top-up, which is negligible relative to the 8% platform fee on prize pots
5. **Proven stack** — well-understood integration patterns, lowest risk

---

## Cost Model

| Scenario | Stripe fee | Per league of 20 players |
|---|---|---|
| Top-up (£5 UK card) | ~27p per transaction | ~£5.40 gross fees |
| Prize payout (bank transfer) | £0 for standard (2–5 days); 1% for instant | £0–varies |
| Platform fee collected | 8% of £100 pot = £8 | £8 income |
| Net platform margin after top-up fees | ~£2.60 per 20-player league | |

> Platform fee income (£8) significantly exceeds payment processing costs (~£5.40) on a 20-player league. Margin improves with more players per league.

---

## Decision

**Pending GATE approval.** Recommendation is Stripe.

Once approved:
1. Human creates Stripe account at dashboard.stripe.com
2. API keys added to Supabase Edge Function secrets (not source code)
3. Stripe Connect configured for payouts
4. PYR-27 (Wallet Edge Functions) unblocked

---

## Consequences

- **If approved:** PYR-27 backend wallet work proceeds with real Stripe integration
- **If rejected in favour of Checkout.com:** ~2 additional weeks integration time; separate KYC vendor needed
- **If rejected entirely:** Paid features cannot launch — free leagues only
