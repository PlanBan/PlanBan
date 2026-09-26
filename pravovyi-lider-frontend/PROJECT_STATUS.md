# PROJECT STATUS — Pravovyi Lider

Last updated: 2026-09-26

This file is a recovery checkpoint so work can resume from GitHub without relying on chat state.

## Completed

- [x] Responsive standalone `index.html`
- [x] Mobile navigation
- [x] Section navigation / CTA links
- [x] Reviews carousel
- [x] FAQ accordion
- [x] Three real lead forms
- [x] Supabase `website_leads` table
- [x] RLS for staff-only reading/updating
- [x] Server-side rate limiting
- [x] Public Edge Function `submit-lead` with JWT verification
- [x] Server-side input validation
- [x] Honeypot bot trap
- [x] SHA-256 IP hashing
- [x] Authenticated `admin.html`
- [x] Lead search/filter
- [x] Lead status changes
- [x] CSV export
- [x] Standalone admin implementation (no JS CDN dependency)
- [x] README updated for backend workflow

## Supabase

Project ref:

    kfvseygjvzljfspgjmiv

Edge Function:

    submit-lead

Endpoint:

    https://kfvseygjvzljfspgjmiv.supabase.co/functions/v1/submit-lead

Database migrations:

    backend/migrations/001_website_leads.sql
    backend/migrations/002_public_rate_limit_rpc.sql

Function source:

    backend/functions/submit-lead/index.ts

## Current security model

Public website:
- sends a public Supabase anon JWT to the Edge Function;
- cannot read `website_leads`;
- cannot write directly to `website_leads`.

Edge Function:
- JWT verification enabled;
- writes with Service Role;
- validates input;
- rate limits by hashed IP.

Admin:
- logs in through Supabase Auth;
- RLS permits SELECT/UPDATE only when `auth.uid()` is an active `organization_members` user.

## Verification already performed

- Supabase migration 001 applied successfully.
- Supabase migration 002 applied successfully.
- Edge Function deployment is ACTIVE, version 1.
- Database insert constraint smoke test passed and test row was deleted.
- RLS policies for `website_leads` are present for authenticated SELECT/UPDATE.
- The rate-limit RPC exists as SECURITY DEFINER.
- Container-side HTTP E2E test could not run because the execution container had no external DNS; this is an environment limitation, not an application response.

## Optional future enhancements

These are not required for the core site to work:
- deploy the static frontend to a hosting provider/domain;
- add email/Telegram notifications for new leads;
- replace the remote reference image with a local licensed asset;
- add analytics/cookie consent if needed;
- add custom domain and production CSP.
