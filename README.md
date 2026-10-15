# Dodoo

**Don't stress, just Dodoo it!** A responsive Indonesian-first planner built with React, TypeScript and Vite.

## Run locally

1. Install Node.js 20.19+ (Vite 7 requirement).
2. Run `npm install`, then `npm run dev`.
3. To enable remote persistence, copy `.env.example` to `.env.local`, set `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`, enable Anonymous Sign-Ins in Supabase Auth, and apply `supabase/migrations/202610150001_dodoo.sql`.
4. Run `npm run build` for the production bundle; `npm run preview` serves it locally.

## Cloudflare Pages

The GitHub Actions workflow at `.github/workflows/cloudflare-pages.yml` builds and deploys the static Vite output to the Cloudflare Pages project `dodoo-planner` on pushes to `main`. Create that Pages project in the Cloudflare dashboard (or run `npx wrangler pages project create dodoo-planner --production-branch main` after authenticating Wrangler), then add these GitHub Actions repository secrets:

- `CLOUDFLARE_API_TOKEN` — token with Cloudflare Pages edit permission.
- `CLOUDFLARE_ACCOUNT_ID` — Cloudflare account ID.
- `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` — the public Supabase project URL and anon/publishable key.

The Vite variables are public client configuration; enforce access with Supabase RLS. Do not add a service-role key or email-provider key to the Pages build.

Tasks and preferences are stored in IndexedDB on the current browser. With Supabase configured, the app creates an anonymous Auth session and upserts tasks to the `tasks` table under that user ID. The UI distinguishes local-only state from a confirmed sync. RLS policies scope rows and private attachment objects by `auth.uid()`. Never put service-role or email-provider keys in Vite environment variables.

## Included

- Task create/edit/duplicate/complete/delete, time validation, overlap warnings, search, categories, priorities, custom colors, date agenda, and weekly calendar.
- Weekly repeat shortcut creates the next eight occurrences with a shared series ID.
- Focus stopwatch stores its state in IndexedDB and resumes after refresh; short rest action; next scheduled task and inter-task rest labels.
- Light/dark/system selection, accent palette and HEX picker, browser notification permission request, local image/PDF attachment metadata, `.ics` export, and share/copy fallback.
- PWA manifest and basic service worker shell cache.

## Supabase and production configuration

Apply the migration in the Supabase SQL editor or via Supabase CLI. It creates `profiles`, `tasks`, and `task_attachments`, enables RLS, creates ownership policies, and provisions a private 5 MB `task-attachments` bucket. Anonymous sign-in must be enabled in the project. The app will remain usable locally if configuration is absent or remote sync fails.

Account linking, verified-email recovery, persistent cross-device attachment upload, email reminders, and a reminder scheduler are not configured in this MVP. Local attachment previews use browser object URLs and are session-local; don't treat them as durable backups. Browser reminders are permission-gated and only reliable while the app can run. Configure any email sender in a server-side Edge Function with provider secrets and a scheduled job; never expose those secrets to the browser. Account linking must use Supabase's supported identity-linking flow and preserve the anonymous user ID.

Deploy the Vite `dist` output to Vercel or Netlify and configure the same two public Supabase variables. Add a catch-all rewrite to `/index.html` if deploying with client-side routes in the future. Do not commit `.env` files.

## Limitations

This is a local-first MVP. Theme/preferences are currently local to the browser; task sync is best-effort and requires the provided migration. The Settings screen explicitly reports missing backend configuration. The email-reminder, account-upgrade and remote attachment flows need the server-side/account setup described above before being offered as production capabilities.
