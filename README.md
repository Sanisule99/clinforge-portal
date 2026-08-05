# ClinForge Patient Result Portal â€” `results.integrishds.com`

A standalone Next.js 14 app, separate from the staff frontend on purpose:
patients never load the admin bundle or auth, and the app stays tiny
(~92 kB) for low-bandwidth handsets.

## Flow

```
SMS link  â”€â”€â–¶  /r/<token>
                  â”‚  POST /portal/session/info   (masked phone, no OTP sent)
                  â–¼
             Verify screen â”€â”€tapâ”€â”€â–¶ POST /portal/session/start   (OTP sent)
                  â–¼
             Code screen  â”€â”€6 digitsâ”€â”€â–¶ POST /portal/session/verify â†’ session JWT
                  â–¼
             Results      â”€â”€â–¶ GET /portal/result        (plain-language cards)
                          â”€â”€â–¶ GET /portal/result/pdf     (if pdf_available)
```

The clinical copy (summaries, meanings) comes from the backend in the
patient's language â€” `lib/i18n.ts` holds only UI chrome.

## Local dev

```bash
cp .env.local.example .env.local     # already points at the Railway API
npm install
npm run dev                          # http://localhost:3100
```

You need a real link token to exercise the flow. Trigger a notify (staff
side), read the raw token from the backend log, then open
`http://localhost:3100/r/<token>`.

## Deploy to Vercel

1. Push this folder to a repo (or a subdir Vercel points at).
2. New Vercel project â†’ framework **Next.js**.
3. Env var: `NEXT_PUBLIC_API_URL = https://lucid-magic-production.up.railway.app`
4. Add domain `results.integrishds.com` (GoDaddy CNAME â†’ Vercel, same as
   clinforge.integrishds.com).

## Backend prerequisites

- `PORTAL_SECRET_KEY` and `PORTAL_BASE_URL` set in Railway (PORTAL_BASE_URL =
  `https://results.integrishds.com`, since it builds the link in the SMS).
- `results.integrishds.com` present in the backend `CORS_ORIGINS` (already added).

## Notes

- `optimizeFonts: false` is set only so the build doesn't fetch Google Fonts
  at build time in restricted CI. Fonts still load at runtime via the `<link>`
  in `app/layout.tsx`. Safe to leave as-is.
- The PDF button is hidden automatically when the backend reports
  `pdf_available: false` (a withheld HIV or critical result), matching the
  "collect in person" rule enforced server-side.
