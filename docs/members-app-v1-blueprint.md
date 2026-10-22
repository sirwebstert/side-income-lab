# Side Income Lab — Members App (V1 Blueprint)

Status: architecture approved for development; NOT deployed. The existing GitHub Pages landing page and affiliate redirects remain unchanged.

## Product
A mobile-first members' opportunity hub. Public landing page drives discovery; members register, choose a country, browse eligible opportunities, bookmark them and opt in separately to marketing email or web push. No paid membership or fabricated exclusivity in V1.

## Proposed stack
- Next.js + TypeScript for app and admin UI, deployed to a supported application host (not GitHub Pages).
- Supabase for managed authentication, Postgres database and row-level security.
- Brevo or comparable permission-based email campaign platform; verify CPA offer email permissions before campaigns.
- Existing GitHub Pages site remains public until migration is explicitly approved.

## Core tables
- profiles: user_id (auth reference), country_code, display_name, created_at.
- categories: id, name, slug, active.
- opportunities: id, title, category_id, description, countries_allowed, affiliate_url_ref, status, reviewed_at, terms, disclosure.
- saved_opportunities: user_id, opportunity_id, saved_at.
- consent_events: user_id, channel (email/sms/push), action (opt_in/opt_out), timestamp, source, policy_version, evidence_ref.
- outbound_clicks: id, user_id nullable, opportunity_id, country_code, source, occurred_at; avoid unnecessary personal data.
- campaign_audit: campaign_id, audience_filter, approved_offer_id, approval_reference, sent_at, provider_report_id.

## Member pages
- /signup, /login, /forgot-password
- /dashboard, /opportunities, /opportunities/[slug], /saved
- /settings (country, notifications, account deletion)
- /admin (role-restricted: opportunities, country eligibility, CSV offer import, metrics, campaign audit)

## Critical security and privacy
- Do not import old plaintext password fields; require fresh signup or approved migration with password reset.
- Do not bulk-email historical Freebies Vault contacts without verifiable marketing permission.
- Verify each CPA offer allows email/push/SMS traffic and required creatives before dispatch.
- Apply Supabase RLS, admin roles, rate limiting, bot protection, secure secrets, unsubscribe and suppression lists.
- Country eligibility enforced server-side, not only by interface filters.
- Separate transactional account emails from promotional campaigns.
- CSV imports must validate fields, remove duplicates and quarantine sensitive columns.
- Measure delivery, clicks and *approved* leads; never equate clicks with conversions.

## Build sequence
1. Scaffold app in a separate directory or branch; do not disrupt current live landing page.
2. Implement auth, country selection, opportunities database and responsive dashboard.
3. Implement admin CRUD, offer import and tracking.
4. Add consent management and email-provider integration; test with opted-in test accounts.
5. Test security, accessibility, mobile UI, and affiliate compliance before production.
6. Deploy staging, then migrate public navigation only after approval.

## Outstanding decisions
Hosting budget, app domain, privacy/terms owner details, email provider plan, and verified source of subscriber consent.
