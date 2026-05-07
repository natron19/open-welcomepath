# WelcomePath Demo

Welcome new members with a 30-day path that builds belonging, not just compliance.

A single-feature demo of the R.O.O.T.S. onboarding framework: Relationships,
Orientation, Opportunities, Training, Stories. Enter a few details about a
new community member and get back a complete 30-day path with activities
mapped to all five root systems.

<!-- Add screenshot of the path show page (five-root map + weekly panels) here.
     Recommended: 1400×900, dark mode, with at least two weekly panels visible. -->

## Why I Built This

I'm building a multi-tenant SaaS suite for community-driven organizations.
WelcomePath is the onboarding tool in that suite. The full product does cohort
tracking, guide assignments, integration assessments, and per-organization path
libraries. This demo isolates the single most valuable action: generating a path.
If the path is good, the rest is worth building.

Most onboarding tools are checklists. Belonging is not a checklist. The R.O.O.T.S.
framework is my answer to that.

This demo is open source under the MIT license. Clone it, tune the prompt in the
admin panel, and see how the output changes.

## Quick Start

1. Clone this repo
2. Run `bin/setup`
3. Add your Gemini API key to `.env`
4. Run `bin/dev`
5. Visit http://localhost:3000 and sign in with the credentials below

### Default Login

After `rails db:seed`:

| Field    | Value            |
|----------|------------------|
| Email    | demo@example.com |
| Password | password123      |
| Role     | Admin            |

A sample onboarding path is seeded automatically for the demo user.

## Editing the AI Prompt

The prompt that generates paths is fully editable in the admin UI:

1. Sign in as `demo@example.com` / `password123`
2. Navigate to `/admin/ai_templates`
3. Click `welcomepath_path_v1`
4. Edit the system prompt or user prompt template
5. Use the test panel on the right to run Gemini with sample variables before saving
6. Save — the next path generated uses the updated prompt

This is the fastest way to tune the output without touching any code.

## What This Demo Does Not Do

This demo is intentionally scoped. The following features exist in the full
production product and are deliberately absent here:

- **Member enrollment tracking.** The production app tracks individual members
  through their assigned path with completion timestamps and milestone attainment.
  The demo stops at path generation.
- **Guide assignment.** In production, each path can be assigned to a guide
  who receives notifications and tracks the member's progress.
- **Peer cohort logic.** The production app groups members into cohorts and
  surfaces cross-cohort connections. Not in scope for the demo.
- **Integration assessment.** A structured mid-path check that measures belonging
  indicators. Production only.
- **Multi-tenancy.** No organizations, memberships, or invitations. Single user only.
- **Connection and story curation.** Separate AI features for peer introductions
  and story selection. Not seeded in this demo.
- **Multi-language support.** English only. Production supports the locale of the
  host community.
- **File uploads, OAuth, Stripe.** None of the above.

## Stack

| Layer | Choice |
|---|---|
| Framework | Rails 8.1 |
| Database | PostgreSQL with UUID primary keys |
| Auth | Rails native (`has_secure_password`, sessions) |
| CSS | Bootstrap 5 dark mode (CDN) |
| JavaScript | Stimulus + Turbo via importmap |
| AI | Google Gemini via `gemini-ai` gem |
| Queue / Cache / Cable | Solid Stack (no Redis) |
| Testing | RSpec |
| Domain models | `OnboardingPath`, `PathActivity` |

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `APP_NAME` | `"Open Demo Starter"` | Displayed in the navbar and title |
| `APP_TAGLINE` | — | Shown in the footer |
| `APP_DESCRIPTION` | — | Shown on the landing page |
| `GEMINI_API_KEY` | (required) | Your Google Gemini API key — get one free at https://aistudio.google.com/app/apikey |
| `AI_CALLS_PER_USER_PER_DAY` | `50` | Daily AI call budget per user |
| `AI_GLOBAL_TIMEOUT_SECONDS` | `15` | Gemini request timeout in seconds |

Copy `.env.example` to `.env` and fill in your values.

## AI Safety Posture

**What this app enforces:**
- Per-user daily call cap (default: 50/day, set via `AI_CALLS_PER_USER_PER_DAY`)
- Pre-flight gatekeeper: input length limit, prompt injection patterns, profanity filter
- Hard output token cap per template (3000 tokens for path generation)
- Configurable request timeout (default: 15s)
- Full request log with status, tokens, duration, and cost estimate
- Fail-soft UI: errors render an inline alert, never crash the page
- AI disclaimer on every generated path page

**App-specific tuning:**
- Temperature set to 0.5 (lower than default) for more consistent JSON structure
- Max output tokens raised to 3000 to accommodate five full root sections
- Structural constraint in the system prompt ("you cannot produce a path that skips a root") is the primary reliability lever

**Deliberately omitted (with rationale):**
- No PII scrubbing — demo apps have no production user data
- No content moderation API — Gemini's built-in safety filters are sufficient
- No automatic retries — avoids stacking costs on transient failures
- No RAG or vector DB — single-shot prompts only
- No streaming — synchronous calls keep the code simple

See `app/services/ai_gatekeeper.rb` and `app/services/ai_budget_checker.rb` to extend.

## Cost

Path generation uses `gemini-2.5-flash`. A typical request consumes roughly 800–1200
input tokens and 600–1000 output tokens. At current pricing ($0.15/1M input,
$0.60/1M output), a single path costs well under $0.01. The free tier covers typical
demo usage without charges.

## License

MIT — see [LICENSE](LICENSE)
