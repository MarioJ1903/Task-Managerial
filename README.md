# Dodoo

**Don't stress, just Dodoo it!** A responsive Indonesian-first planner built with React, TypeScript and Vite.

## Run locally

1. Install Node.js 20.19+ (Vite 7 requirement).
2. Run `npm install`, then `npm run dev`.
3. Copy `.env.example` to `.env.local`, set `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY`, and apply `supabase/migrations/202610150001_dodoo.sql`.
4. Users must create an account or sign in with email and password. Email confirmation and password recovery require working Auth email delivery; configure custom SMTP in Supabase for users outside your project team.
5. Run `npm run build` for the production bundle; `npm run preview` serves it locally.

## Cloudflare Workers

Run `npm run deploy` after authenticating Wrangler to publish the Vite assets and Worker. GitHub Actions also deploys on pushes to `main`; configure these repository secrets:

- `CLOUDFLARE_API_TOKEN` — token with permission to deploy Workers and assets.
- `CLOUDFLARE_ACCOUNT_ID` — Cloudflare account ID.
- `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY` — the public Supabase project URL and publishable key.

The Vite variables are public client configuration; enforce access with Supabase RLS. Do not add a service-role key or email-provider key to the Worker build.

Users must authenticate before the planner is shown. Tasks sync to the `tasks` table under the signed-in user's ID; profiles and preferences use `profiles`. Per-account IndexedDB caches support local continuity. Supabase RLS scopes rows and private attachment objects by `auth.uid()`. Never put service-role or email-provider keys in Vite environment variables.

## Included

- Task create/edit/duplicate/complete/delete, time validation, overlap warnings, search, categories, priorities, custom colors, date agenda, and weekly calendar.
- Weekly repeat shortcut creates the next eight occurrences with a shared series ID.
- Focus stopwatch stores its state in IndexedDB and resumes after refresh; short rest action; next scheduled task and inter-task rest labels.
- Light/dark/system selection, accent palette and HEX picker, browser notification permission request, local image/PDF attachment metadata, `.ics` export, and share/copy fallback.
- PWA manifest and basic service worker shell cache.

## Supabase and production configuration

Apply the migration in the Supabase SQL editor or via Supabase CLI. It creates `profiles`, `tasks`, and `task_attachments`, enables RLS, creates ownership policies, and provisions a private 5 MB `task-attachments` bucket. Email/password sign-ups and logins are enabled; anonymous sign-in is not needed by the app.

Password reset and password changes are supported through Supabase Auth. Custom SMTP must be configured for reliable email verification and password recovery. Persistent cross-device attachment upload, email reminders, and a reminder scheduler are not configured in this MVP. Attachment previews remain local to the account's browser; don't treat them as durable backups. Browser reminders are permission-gated and only reliable while the app can run.

Deploy the Vite `dist` output to Vercel or Netlify and configure the same two public Supabase variables. Add a catch-all rewrite to `/index.html` if deploying with client-side routes in the future. Do not commit `.env` files.

## Limitations

This is a local-first MVP. Theme/preferences are currently local to the browser; task sync is best-effort and requires the provided migration. The Settings screen explicitly reports missing backend configuration. The email-reminder, account-upgrade and remote attachment flows need the server-side/account setup described above before being offered as production capabilities.
