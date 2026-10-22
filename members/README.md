# Side Income Lab Members — V1 scaffold

**Status:** Source scaffold only. Not deployed; signup/login not operational until a Supabase project, environment variables, SQL setup, and hosted runtime are configured. No email sending or admin panel yet.

## Run locally
1. Install Node.js 20+.
2. In `members/`, run `npm install`.
3. Create a Supabase project; run `supabase/schema.sql` in its SQL editor after review.
4. Copy `.env.example` to `.env.local`, fill Supabase URL and publishable/anon key. **Never commit service-role keys.**
5. Configure Supabase Auth redirect URLs for your local and eventual hosted domains.
6. Run `npm run dev` and open http://localhost:3000.

## Implemented
- Responsive premium landing, login, signup, reset/update password UI.
- Supabase authentication wiring and profiles-on-signup trigger.
- Protected-by-client-redirect dashboard (not sufficient for sensitive data; RLS is enforced in database).
- Published opportunities read filtered by member country.

## Not yet implemented
- Admin opportunity management and CSV import, saved opportunities, transactional email configuration, consent persistence, bulk email sending, click attribution, push notifications, deployment and tests.
- Server-side authentication guard, stronger country eligibility enforcement and full privacy/terms pages.

**Safety:** Never import legacy password columns. No marketing sends without documented consent and offer traffic approval. Existing public GitHub Pages website is unchanged.
