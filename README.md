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

## Responsible AI

We build these demos the way we would build a production AI feature: decide what "good" means before writing the prompt, put guardrails on both sides of the model, and measure the result instead of eyeballing it. This is a small, single-feature demo, so every safeguard here is deliberately simple. Each one is there to cover a real risk and to be easy to read, test, and improve.

### Guardrails

**Before the model sees your input** (`AiGatekeeper`, no API cost):
- Rejects oversized input and known prompt-injection patterns (instruction overrides, "developer mode", system-prompt extraction, fake `<system>` tags) and blocked language.

**Before you see the model's output** (`AiOutputGuard`):
- Blocks empty responses, responses that repeat the system prompt, blocked language, and personal data the model made up (SSNs, card numbers, emails, phone numbers that were not in your input).
- `welcomepath_path_v1` must return valid JSON with `relationships`, `orientation`, `opportunities`, `training`, `stories`, or the response is not shown.

**Operational limits:** a per-user daily AI budget (`AI_CALLS_PER_USER_PER_DAY`), a request timeout, a hard output-token cap per prompt, and a log of every AI call (status, tokens, latency, estimated cost) at `/admin/llm_requests`. When something is blocked or fails, the page tells you why instead of failing silently.

**Specific to this app:**
- AI disclaimer on every generated path page

### How we evaluate it

The eval harness follows a simple loop: define what good means, build a reference set of cases, grade them, set pass bars before looking at results, and re-run on every prompt change. Details are in [`docs/ai-evals.md`](docs/ai-evals.md).

| What we check | How | Run it |
|---|---|---|
| Guardrails catch attacks and leave normal input alone | Offline attack and look-alike suite, no API cost | `bin/rails evals:guardrails` |
| Output has the right shape | Code checks: required fields, counts, lengths | `bin/rails evals:run` |
| Output is actually good | An LLM judge scores each case 1–5 against a written rubric, after first proving it agrees with human-labeled examples | `bin/rails evals:run` |
| Latency, cost, and error rate | Read from the request log for each eval case | `bin/rails evals:run` |
| The real feature works in a browser | Headless Chrome walks the main AI feature, plus a blocked-input journey | Maintainer's fleet test harness, run before releases |

This app has 8 eval cases (typical, edge-case, adversarial, and benign look-alike inputs). The judge scores it on:

- **Useful:** The path builds belonging (real relationships, early contribution, sharing the member's own story), not just compliance tasks like reading policies and completing forms.
- **Accurate:** Activities fit the stated community type, member type, and background, and work toward the stated integration goal rather than being generic.
- **Steerable:** Every activity name is concrete and action-oriented, and each description explains in one to three sentences how to do it.

**Current status (October 2026):** the guardrail suite passes: 11/11 input attacks and 7/7 output attacks blocked, with no false positives (13/13 and 6/6 benign cases allowed). Live-model eval baselines are being run next and will be published here. Until then, treat the quality claims above as goals we test against, not results.

### What this demo does and doesn't do

**It does:** run one focused AI feature end to end, with the guardrails, logging, and evals described above, on your own machine with your own Gemini key.

**It doesn't (yet):**
- Guarantee correct output. Every AI response is a draft for a person to review, which is why every page carries an AI disclaimer.
- Catch every attack. The input and output guards are pattern-based. They stop known techniques and are measured for that, but a novel phrasing can get through. That is why the output guard and the evals exist as a second layer.
- Scrub personal data from what you type. Don't paste anything sensitive into a local demo.
- Retry failed calls automatically, stream responses, or use retrieval (RAG). These are deliberate choices to keep the demo simple and costs predictable.

## Contributing and feedback

This project is open source and we want it to be useful to real people. Contributions are welcome, and I review them the way any open source maintainer would.

- **Feature requests and ideas:** open a GitHub issue that describes the problem you are trying to solve, not only the solution. Examples of the outputs you wish you got are especially helpful.
- **Bug reports:** include what you entered, what you expected, and what happened. For AI quality problems, the output itself is the most useful evidence.
- **Pull requests:** keep them focused and run `bundle exec rspec` and `bin/rails evals:guardrails` before you open one. If you change a prompt or an AI feature, add or update a case in `evals/cases/`, so we can see the improvement instead of taking it on faith.
- **Reviews:** I read every issue and review every pull request personally. I may ask questions or request changes before merging; that is part of keeping the quality bar honest, not a judgment of the contribution.
- **Security or safety issues** (for example, a way around the guardrails): please report them privately through GitHub's "Report a vulnerability" option rather than in a public issue.

## Cost

Path generation uses `gemini-2.5-flash`. A typical request consumes roughly 800–1200
input tokens and 600–1000 output tokens. At current pricing ($0.15/1M input,
$0.60/1M output), a single path costs well under $0.01. The free tier covers typical
demo usage without charges.

## License

MIT — see [LICENSE](LICENSE)
